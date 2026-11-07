import SwiftUI
import Foundation

struct AppPage2View: View {
    @EnvironmentObject private var store: AppStore
    @State private var showOnlyNonZero = false
    @State private var selectedCategoryRaw: String?
    @State private var showingExpenseList = false

    private let categoryRawOrder = ["餐饮", "交通", "购物", "其它"]

    var body: some View {
        NavigationStack {
            List {
                summarySection
                if store.todayExpenses.isEmpty {
                    emptySection
                } else {
                    categorySection
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("分类")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle(isOn: $showOnlyNonZero) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .toggleStyle(.button)
                }
            }
            .sheet(isPresented: $showingExpenseList) {
                if let raw = selectedCategoryRaw, let category = AppCategory(rawValue: raw) {
                    AppPage2CategoryExpenseList(categoryRaw: raw, category: category)
                        .environmentObject(store)
                }
            }
        }
    }

    var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("今日分类合计")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(AppPage2Format.currency(store.todayTotal))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                HStack {
                    Label("\(store.todayExpenses.count) 笔", systemImage: "list.bullet")
                    Spacer()
                    Label(store.isOverBudget ? "已超预算" : "预算内", systemImage: store.isOverBudget ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(store.isOverBudget ? Color.red : Color.green)
                }
                .font(.footnote)
            }
            .padding(.vertical, 8)
        }
    }

    var emptySection: some View {
        Section {
            AppPage2EmptyState()
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
        }
    }

    private var categorySection: some View {
        Section("今天按分类") {
            if filteredCategoryRawOrder.isEmpty {
                HStack {
                    Spacer()
                    Text("没有非零分类")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                ForEach(filteredCategoryRawOrder, id: \.self) { raw in
                    AppPage2CategoryRow(
                        categoryRaw: raw,
                        amount: total(for: raw),
                        count: count(for: raw),
                        total: store.todayTotal,
                        action: {
                            selectedCategoryRaw = raw
                            showingExpenseList = true
                        }
                    )
                }
            }
        }
    }

    private var filteredCategoryRawOrder: [String] {
        showOnlyNonZero ? categoryRawOrder.filter { total(for: $0) > 0 } : categoryRawOrder
    }

    func total(for categoryRaw: String) -> Double {
        store.todayExpenses
            .filter { $0.category.rawValue == categoryRaw }
            .reduce(0) { $0 + $1.amount }
    }

    private func count(for categoryRaw: String) -> Int {
        store.todayExpenses
            .filter { $0.category.rawValue == categoryRaw }
            .count
    }
}

private struct AppPage2CategoryRow: View {
    let categoryRaw: String
    let amount: Double
    let count: Int
    let total: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: AppPage2CategoryIconProvider.icon(for: categoryRaw))
                    .font(.title2)
                    .foregroundStyle(AppPage2CategoryIconProvider.color(for: categoryRaw))
                    .frame(width: 36, height: 36)
                    .background(AppPage2CategoryIconProvider.color(for: categoryRaw).opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 4) {
                    Text(categoryRaw)
                        .font(.headline)
                    Text(count == 0 ? "今天无支出" : "\(count) 笔")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(AppPage2Format.currency(amount))
                        .font(.headline)
                        .monospacedDigit()
                    if total > 0 {
                        Text("\(Int((amount / total) * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("0%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct AppPage2EmptyState: View {
    var body: some View {
        ContentUnavailableView {
            Label("今天还没有支出", systemImage: "tray")
        } description: {
            Text("去「今天」页记下第一笔，这里会按分类汇总。")
        }
    }
}

private struct AppPage2CategoryExpenseList: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let categoryRaw: String
    let category: AppCategory

    var expenses: [AppExpense] {
        store.todayExpenses
            .filter { $0.category.rawValue == categoryRaw }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                if expenses.isEmpty {
                    Section {
                        AppPage2EmptyState()
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                    }
                } else {
                    Section("\(category.rawValue) · 今天") {
                        ForEach(expenses, id: \.id) { expense in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(expense.note.isEmpty ? category.rawValue : expense.note)
                                        .font(.headline)
                                    Text(AppPage2Format.time(expense.date))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(AppPage2Format.currency(expense.amount))
                                    .font(.headline)
                                    .monospacedDigit()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle(category.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

private enum AppPage2Format {
    static func currency(_ value: Double) -> String {
        String(format: "¥%.2f", value)
    }

    static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

private enum AppPage2CategoryIconProvider {
    static func icon(for raw: String) -> String {
        switch raw {
        case "餐饮": return "fork.knife"
        case "交通": return "car.fill"
        case "购物": return "bag.fill"
        default: return "ellipsis.circle.fill"
        }
    }

    static func color(for raw: String) -> Color {
        switch raw {
        case "餐饮": return .orange
        case "交通": return .blue
        case "购物": return .purple
        default: return .gray
        }
    }
}