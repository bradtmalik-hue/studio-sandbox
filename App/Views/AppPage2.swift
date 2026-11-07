import SwiftUI
import Combine

extension AppPayload: ObservableObject {}

struct AppPage2View: View {
    @EnvironmentObject var store: AppPayload
    @State private var searchText = ""
    @State private var selectedType = "全部"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if store.meals.isEmpty {
                    AppPage2EmptyView()
                } else {
                    AppPage2FilterBar(options: typeOptions, selectedType: $selectedType)

                    if groupedByDay.isEmpty {
                        AppPage2EmptyView()
                    } else {
                        List {
                            Section {
                                AppPage2SummaryCard(
                                    totalCount: filteredMeals.count,
                                    totalAmount: filteredMeals.reduce(0) { $0 + $1.amount },
                                    totalCalories: filteredMeals.reduce(0) { $0 + $1.calories },
                                    averageCalories: filteredMeals.isEmpty ? 0 : filteredMeals.reduce(0) { $0 + $1.calories } / Double(filteredMeals.count),
                                    lastDate: filteredMeals.map(\.date).max()
                                )
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())

                            ForEach(groupedByDay, id: \.day) { group in
                                Section {
                                    ForEach(group.meals, id: \.id) { meal in
                                        NavigationLink {
                                            AppPage2MealDetailView()
                                        } label: {
                                            AppPage2MealRow(meal: meal)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                delete(meal)
                                            } label: {
                                                Label("删除", systemImage: "trash")
                                            }
                                        }
                                    }
                                } header: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(dayString(group.day))
                                            .font(.headline)
                                        Text("\(group.meals.count) 次喂食 · \(group.meals.reduce(0) { $0 + $1.calories }, specifier: "%.0f") 千卡")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .contentMargins(.bottom, 96, for: .scrollContent)
                    }
                }
            }
            .navigationTitle("历史")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索食物名称")
        }
    }

    var filteredMeals: [AppMeal] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.meals.filter { meal in
            let matchesType = selectedType == "全部" || meal.mealType.rawValue == selectedType
            let matchesSearch = query.isEmpty
                || meal.foodName.localizedCaseInsensitiveContains(query)
                || meal.note.localizedCaseInsensitiveContains(query)
            return matchesType && matchesSearch
        }
    }

    private var groupedByDay: [(day: Date, meals: [AppMeal])] {
        let dict = Dictionary(grouping: filteredMeals) { Calendar.current.startOfDay(for: $0.date) }
        return dict.keys.sorted(by: >).map { day in
            (day: day, meals: dict[day]!.sorted(by: { $0.date > $1.date }))
        }
    }

    private var typeOptions: [String] {
        var seen = Set<String>()
        var options = ["全部"]
        for meal in store.meals {
            let raw = meal.mealType.rawValue
            if seen.insert(raw).inserted {
                options.append(raw)
            }
        }
        return options
    }

    func delete(_ meal: AppMeal) {
        withAnimation {
            store.meals.removeAll { $0.id == meal.id }
            store.save()
        }
    }

    private func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: date)
    }
}

private struct AppPage2FilterBar: View {
    let options: [String]
    @Binding var selectedType: String

    var body: some View {
        Picker("筛选类型", selection: $selectedType) {
            ForEach(options, id: \.self) { option in
                Text(option).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

private struct AppPage2SummaryCard: View {
    let totalCount: Int
    let totalAmount: Double
    let totalCalories: Double
    let averageCalories: Double
    let lastDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("历史概览", systemImage: "calendar")
                    .font(.headline)
                Spacer()
            }
            HStack {
                AppPage2SummaryMetric(title: "总次数", value: "\(totalCount)", unit: "次")
                Spacer()
                AppPage2SummaryMetric(title: "总份量", value: "\(totalAmount, specifier: "%.0f")", unit: "克")
                Spacer()
                AppPage2SummaryMetric(title: "总热量", value: "\(totalCalories, specifier: "%.0f")", unit: "千卡")
            }
            HStack {
                AppPage2SummaryMetric(title: "平均每餐", value: "\(averageCalories, specifier: "%.0f")", unit: "千卡")
                Spacer()
                if let lastDate = lastDate {
                    AppPage2SummaryMetric(title: "最近记录", value: shortTimeString(lastDate), unit: "")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func shortTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

private struct AppPage2SummaryMetric: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.monospacedDigit())
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

private struct AppPage2MealRow: View {
    let meal: AppMeal

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.title2)
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.foodName)
                    .font(.headline)
                Text(meal.mealType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(timeString(meal.date))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(meal.amount, specifier: "%.0f") 克")
                Text("\(meal.calories, specifier: "%.0f") 千卡")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}