import SwiftUI

struct AppPage2View: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var selectedCategory = "全部"

    var categories: [String] {
        Array(Set(store.completedTodos.map(\.category))).sorted()
    }

    var filteredTodos: [AppTodoItem] {
        var result = store.completedTodos.sorted {
            ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast)
        }
        if selectedCategory != "全部" {
            result = result.filter { $0.category == selectedCategory }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppPage2SummaryCard(
                    total: store.completedTodos.count,
                    todayCompleted: store.todayCompletedCount,
                    todayTotal: store.todayTotalCount
                )
                .padding(.horizontal)
                .padding(.top, 8)

                AppPage2FilterBar(
                    searchText: $searchText,
                    selectedCategory: $selectedCategory,
                    categories: categories
                )
                .padding(.horizontal)
                .padding(.vertical, 8)

                if filteredTodos.isEmpty {
                    ContentUnavailableView(
                        "没有已完成待办",
                        systemImage: "checkmark.circle",
                        description: Text("完成一个待办后，会显示在这里。")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredTodos) { item in
                            AppPage2Row(item: item)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("已完成")
            .background(Color(.systemGroupedBackground))
        }
    }
}

private struct AppPage2SummaryCard: View {
    let total: Int
    let todayCompleted: Int
    let todayTotal: Int

    private var completionRate: Int {
        guard todayTotal > 0 else { return 0 }
        return Int((Double(todayCompleted) / Double(todayTotal)) * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("完成概览")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                AppPage2StatItem(value: "\(total)", label: "已完成")
                Spacer()
                AppPage2StatItem(value: "\(todayCompleted)/\(todayTotal)", label: "今日进度")
                Spacer()
                AppPage2StatItem(value: "\(completionRate)%", label: "完成率")
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct AppPage2StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AppPage2FilterBar: View {
    @Binding var searchText: String
    @Binding var selectedCategory: String
    let categories: [String]

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索已完成待办", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["全部"] + categories, id: \.self) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            Text(category)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    selectedCategory == category ? Color.accentColor.opacity(0.2) : Color(.secondarySystemGroupedBackground),
                                    in: Capsule()
                                )
                                .foregroundStyle(selectedCategory == category ? Color.accentColor : Color.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct AppPage2Row: View {
    let item: AppTodoItem

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .strikethrough(item.isCompleted)
                Text(item.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("完成于 \(Self.timeFormatter.string(from: item.completedAt ?? item.dueDate))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(item.priorityDisplayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.12), in: Capsule())
                .foregroundStyle(Color.accentColor)
        }
    }
}