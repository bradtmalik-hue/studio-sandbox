import SwiftUI
import Foundation

struct AppPage3View: View {
    @EnvironmentObject var store: AppStore
    @State private var sortByAmount = false
    @State private var showTargetLine = true
    @State private var showValueLabels = true

    private let calendar = Calendar.current

    private var last7Days: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.sorted()
    }

    private var dailyTotals: [AppPage3DailyStat] {
        last7Days.map { day in
            let total = store.records
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.amountMl }
            return AppPage3DailyStat(id: Date(), date: Date(), total: 0)
        }
    }

    private var sortedDailyTotals: [AppPage3DailyStat] {
        if sortByAmount {
            return dailyTotals.sorted { $0.total > $1.total }
        } else {
            return dailyTotals
        }
    }

    private var total7: Int {
        dailyTotals.reduce(0) { $0 + $1.total }
    }

    private var averageMl: Int {
        total7 / 7
    }

    private var achievedDays: Int {
        dailyTotals.filter { $0.total >= store.dailyGoalMl }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    ContentUnavailableView(
                        "还没有喝水记录",
                        systemImage: "drop.fill",
                        description: Text("去「今天」页记一杯水，这里会显示最近 7 天的统计。")
                    )
                } else {
                    List {
                        Section {
                            AppPage3SummaryCard(
                                averageMl: averageMl,
                                achievedDays: achievedDays,
                                totalMl: total7,
                                goalMl: store.dailyGoalMl
                            )
                        }

                        Section("最近 7 天喝水量") {
                            Picker("排序", selection: $sortByAmount) {
                                Text("按日期").tag(false)
                                Text("按喝水量").tag(true)
                            }
                            .pickerStyle(.segmented)

                            Toggle("显示目标线", isOn: $showTargetLine)
                            Toggle("显示数值", isOn: $showValueLabels)

                            AppPage3BarChart(dailyTotals: sortedDailyTotals, goal: store.dailyGoalMl, showTargetLine: showTargetLine, showValueLabels: showValueLabels, maxHeight: 0)
                            .padding(.top, 4)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("统计")
        }
    }
}

struct AppPage3DailyStat: Identifiable {
    let id: Date
    let date: Date
    let total: Int
}

struct AppPage3SummaryCard: View {
    let averageMl: Int
    let achievedDays: Int
    let totalMl: Int
    let goalMl: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("近 7 天概览", systemImage: "chart.bar.fill")
                .font(.headline)

            Text("每日目标 \(goalMl) 毫升")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                AppPage3Metric(value: averageMl, unit: "毫升", label: "平均每天")
                AppPage3Metric(value: achievedDays, unit: "天", label: "达标天数")
                AppPage3Metric(value: totalMl, unit: "毫升", label: "总喝水量")
            }
        }
        .padding(.vertical, 4)
    }
}

struct AppPage3Metric: View {
    let value: Int
    let unit: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AppPage3BarChart: View {
    let dailyTotals: [AppPage3DailyStat]
    let goal: Int
    let showTargetLine: Bool
    let showValueLabels: Bool

    private var maxValue: Int {
        max(dailyTotals.map(\.total).max() ?? 0, goal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(dailyTotals) { item in
                    VStack(spacing: 4) {
                        Text("\(item.total)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .opacity(showValueLabels ? 1 : 0)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(barColor(for: item.total))
                            .frame(height: barHeight(for: item.total))

                        Text(dayLabel(for: item.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 180, alignment: .bottom)

            if showTargetLine {
                HStack {
                    Spacer()
                    Text("目标 \(goal) 毫升")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func barHeight(for value: Int) -> CGFloat {
        let maxHeight: CGFloat = 120
        guard maxValue > 0 else { return 8 }
        return max(8, CGFloat(value) / CGFloat(maxValue) * maxHeight)
    }

    private func barColor(for value: Int) -> Color {
        value >= goal ? Color.cyan : Color.blue.opacity(0.7)
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}