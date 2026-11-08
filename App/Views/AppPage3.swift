import Foundation
import SwiftUI

private struct AppPage3CategoryStat: Identifiable {
    let id: String
    let category: String
    let quantity: Double
}

struct AppPage3View: View {
    @EnvironmentObject var store: AppInventoryStore
    @State private var sortOrder = "数量降序"
    @State private var selectedCategory = "全部"
    @State private var onlySevenDays = false

    private var allCategories: [String] {
        ["全部"] + Array(Set(store.items.map(\.category))).sorted()
    }

    private var categoryStats: [AppPage3CategoryStat] {
        let breakdown = store.categoryBreakdown.map { AppPage3CategoryStat(id: $0.0, category: $0.0, quantity: $0.1) }
        let filtered = selectedCategory == "全部" ? breakdown : breakdown.filter { $0.category == selectedCategory }
        switch sortOrder {
        case "数量降序":
            return filtered.sorted { $0.quantity > $1.quantity }
        case "名称升序":
            return filtered.sorted { $0.category < $1.category }
        default:
            return filtered
        }
    }

    private var displayedExpiringItems: [AppPetSupplyItem] {
        let items = onlySevenDays
            ? store.expiringSoonItems.filter { daysRemaining(until: $0.expirationDate) <= 7 }
            : store.expiringSoonItems
        return items.sorted { $0.expirationDate < $1.expirationDate }
    }

    private func daysRemaining(until date: Date) -> Int {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: date)
        return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        AppPage3SummaryCard(title: "物品总数", value: Double(store.totalItemCount), unit: "件", color: .brown)
                        AppPage3SummaryCard(title: "总数量", value: store.totalQuantity, unit: "件", color: .blue)
                        AppPage3SummaryCard(title: "快过期", value: Double(store.expiringSoonCount), unit: "件", color: .orange)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section {
                    Picker("排序", selection: $sortOrder) {
                        Text("数量降序").tag("数量降序")
                        Text("名称升序").tag("名称升序")
                    }
                    .pickerStyle(.segmented)

                    Picker("分类", selection: $selectedCategory) {
                        ForEach(allCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle("只看 7 天内过期", isOn: $onlySevenDays)
                }

                Section("各类物品数量占比") {
                    if categoryStats.isEmpty {
                        ContentUnavailableView {
                            Label("暂无分类数据", systemImage: "chart.pie")
                        } description: {
                            Text("添加物品后可查看各类数量占比")
                        }
                    } else {
                        ForEach(categoryStats) { stat in
                            AppPage3CategoryRow(stat: stat, totalQuantity: max(store.totalQuantity, 0.001))
                        }
                    }
                }

                Section("快过期清单") {
                    if displayedExpiringItems.isEmpty {
                        ContentUnavailableView {
                            Label("没有快过期物品", systemImage: "checkmark.circle")
                        } description: {
                            Text("所有物品都在安全保质期内")
                        }
                    } else {
                        ForEach(displayedExpiringItems) { item in
                            AppPage3ExpiringRow(item: item, daysRemaining: daysRemaining(until: item.expirationDate))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("统计")
        }
    }
}

private struct AppPage3SummaryCard: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color

    private var formattedValue: String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formattedValue)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(color)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct AppPage3CategoryRow: View {
    let stat: AppPage3CategoryStat
    let totalQuantity: Double

    private var percentage: Double {
        guard totalQuantity > 0 else { return 0 }
        return min(stat.quantity / totalQuantity, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(color(for: stat.category))
                    .frame(width: 10, height: 10)
                Text(stat.category)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(String(format: "%.1f", stat.quantity))
                    .font(.subheadline.monospacedDigit())
                Text(String(format: "%.0f%%", percentage * 100))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: percentage)
                .tint(color(for: stat.category))
        }
    }

    private func color(for category: String) -> Color {
        let palette: [Color] = [.brown, .blue, .orange, .green, .pink, .purple, .teal]
        var hash = 0
        for scalar in category.unicodeScalars {
            hash = (hash &+ Int(scalar.value)) % palette.count
        }
        return palette[hash]
    }
}

private struct AppPage3ExpiringRow: View {
    let item: AppPetSupplyItem
    let daysRemaining: Int

    private var expirationText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: item.expirationDate)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.exclamationmark")
                .foregroundStyle(daysRemaining <= 7 ? .red : .orange)
                .frame(width: 30, height: 30)
                .background((daysRemaining <= 7 ? Color.red : Color.orange).opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Image(systemName: "tag")
                        Text(item.category)
                    }
                    HStack(spacing: 2) {
                        Image(systemName: "shippingbox")
                        Text("\(String(format: "%.0f", item.quantity)) \(item.unit)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(expirationText)
                    .font(.caption)
                Text(daysRemaining < 0 ? "已过期" : "剩余 \(daysRemaining) 天")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(daysRemaining <= 7 ? .red : .orange)
            }
        }
        .padding(.vertical, 4)
    }
}