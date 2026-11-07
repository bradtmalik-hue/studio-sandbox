import SwiftUI

struct AppPage3View: View {
    let store: AppWaterStore
    @State private var selectedRange = 7
    @State private var showAverageLine = true
    @State private var showGoalLine = true

    private var hasData: Bool {
        !store.records.isEmpty
    }

    private var dayStats: [AppPage3DayStat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -(selectedRange - 1), to: today),
              let end = calendar.date(byAdding: .day, value: 1, to: today) else {
            return []
        }
        let recent = store.records.filter { $0.date >= start && $0.date < end }
        let grouped = Dictionary(grouping: recent) { calendar.startOfDay(for: $0.date) }
        return (0..<selectedRange).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            let records = grouped[date] ?? []
            let total = records.reduce(0.0) { $0 + $1.amount }
            return AppPage3DayStat()
        }
    }

    private var average: Double {
        guard !dayStats.isEmpty else { return 0 }
        return dayStats.reduce(0.0) { $0 + $1.total } / Double(dayStats.count)
    }

    private var goalDays: Int {
        dayStats.filter { $0.total >= 2000 }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if hasData {
                    statisticsList
                } else {
                    AppPage3EmptyState()
                }
            }
            .navigationTitle("统计")
        }
    }

    private var statisticsList: some View {
        List {
            Section {
                Picker("范围", selection: $selectedRange) {
                    Text("最近 7 天").tag(7)
                    Text("最近 14 天").tag(14)
                }
                .pickerStyle(.segmented)

                Toggle(isOn: $showAverageLine) {
                    Label("显示平均线", systemImage: "line.horizontal.3")
                }

                Toggle(isOn: $showGoalLine) {
                    Label("显示目标线", systemImage: "flag.fill")
                }
            }

            Section("概览") {
                AppPage3SummaryCard(average: average, goalDays: goalDays)
            }

            Section("最近\(selectedRange)天") {
                AppPage3BarChart(dayStats: dayStats, showAverage: showAverageLine, showGoal: showGoalLine, average: average, goal: 2000, minHeight: 0)
            }

            Section("每日明细") {
                ForEach(dayStats) { stat in
                    AppPage3DayRow(stat: stat)
                }
            }

            Section {
                Color.clear.frame(height: 96)
            }
        }
        .contentMargins(.bottom, 96, for: .scrollContent)
    }
}

struct AppPage3DayStat: Identifiable {
    let id: Date
    let date: Date
    let total: Double
    let count: Int
}

struct AppPage3SummaryCard: View {
    let average: Double
    let goalDays: Int

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("平均每天")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(Int(average))")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("毫升")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))

            VStack(spacing: 4) {
                Text("达标天数")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(goalDays)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("目标 2000 毫升")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct AppPage3BarChart: View {
    let dayStats: [AppPage3DayStat]
    let showAverage: Bool
    let showGoal: Bool
    let average: Double
    let goal: Double
    let minHeight: CGFloat

    private var maxTotal: Double {
        max(goal, dayStats.map(\.total).max() ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(dayStats) { stat in
                        VStack(spacing: 4) {
                            Text("\(Int(stat.total))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: 22, height: barHeight(for: stat.total))
                            Text(shortDay(for: stat.date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            if showAverage {
                Text("平均每天 \(Int(average)) 毫升")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            if showGoal {
                Text("目标 \(Int(goal)) 毫升")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }

    private func barHeight(for total: Double) -> CGFloat {
        let ratio = CGFloat(total / maxTotal)
        return max(minHeight, ratio * 120)
    }

    private func shortDay(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

struct AppPage3DayRow: View {
    let stat: AppPage3DayStat

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(fullDay(for: stat.date))
                    .font(.headline)
                Text("\(stat.count) 条记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("\(Int(stat.total)) 毫升")
                .font(.title3.weight(.semibold))
                .foregroundColor(stat.total >= 2000 ? Color.green : Color.blue)
        }
        .padding(.vertical, 4)
    }

    private func fullDay(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

struct AppPage3EmptyState: View {
    var body: some View {
        ContentUnavailableView(
            "还没有饮水记录",
            systemImage: "drop.fill",
            description: Text("记录几杯水后，这里会展示统计")
        )
    }
}