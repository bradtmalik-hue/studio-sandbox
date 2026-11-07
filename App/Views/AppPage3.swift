import SwiftUI
import Foundation

struct AppPage3DayStat: Identifiable {
    let id = UUID()
    let date: Date
    let total: Int
}

struct AppPage3View: View {
    @EnvironmentObject var store: AppStore
    @State private var displayMode: AppPage3DisplayMode = .chart
    @State private var showGoalLine: Bool = true

    enum AppPage3DisplayMode: String, CaseIterable, Identifiable {
        case chart = "柱状图"
        case list = "列表"
        var id: String { rawValue }
    }

    var calendar: Calendar { Calendar.current }

    var startOfToday: Date {
        calendar.startOfDay(for: Date())
    }

    private var dayStats: [AppPage3DayStat] {
        (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: startOfToday) else { return nil }
            let total = store.records
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.amount }
            return AppPage3DayStat(date: Date(), total: 0)
        }
    }

    private var totalInLast7Days: Int {
        dayStats.reduce(0) { $0 + $1.total }
    }

    private var averageDaily: Int {
        guard !dayStats.isEmpty else { return 0 }
        return totalInLast7Days / dayStats.count
    }

    private var achievedDays: Int {
        dayStats.filter { $0.total >= 2000 }.count
    }

    private var hasAnyRecords: Bool {
        !store.records.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if hasAnyRecords {
                        HStack(spacing: 12) {
                            AppPage3SummaryCard(
                                title: "平均每天",
                                value: "\(averageDaily)",
                                unit: "毫升",
                                icon: "drop.fill",
                                color: .blue
                            )
                            AppPage3SummaryCard(
                                title: "达标天数",
                                value: "\(achievedDays)",
                                unit: "天",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                        }
                        .padding(.horizontal)

                        Picker("显示模式", selection: $displayMode) {
                            ForEach(AppPage3DisplayMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)

                        Toggle(isOn: $showGoalLine) {
                            Label("显示2000毫升目标线", systemImage: "line.diagonal")
                        }
                        .padding(.horizontal)

                        if displayMode == .chart {
                            AppPage3BarChart(dayStats: dayStats, goal: 2000, showGoalLine: showGoalLine, dateFormatter: Date(), maxH: 0, maxH: 0)
                                .padding(.horizontal)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(dayStats) { stat in
                                    AppPage3SummaryRow(dayStat: stat, dateFormatter: Date())
                                }
                            }
                            .padding(.horizontal)
                        }

                        HStack {
                            Text("最近7天合计")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(totalInLast7Days) 毫升")
                                .bold()
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)

                    } else {
                        ContentUnavailableView(
                            "暂无喝水记录",
                            systemImage: "drop",
                            description: Text("去「今天」页记录第一杯水吧")
                        )
                    }
                }
                .padding(.vertical)
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("统计")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.load()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("刷新")
                }
            }
        }
    }
}

struct AppPage3SummaryCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title)
                    .bold()
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct AppPage3BarChart: View {
    let dayStats: [AppPage3DayStat]
    let goal: Int
    let showGoalLine: Bool

    private var maxTotal: Int {
        max(dayStats.map(\.total).max() ?? 0, 1)
    }

    var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M/d"
        return f
    }

    private func barHeight(for total: Int) -> CGFloat {
        let maxH: CGFloat = 150
        guard maxTotal > 0 else { return 0 }
        return maxH * CGFloat(total) / CGFloat(maxTotal)
    }

    private func goalLineHeight() -> CGFloat {
        let maxH: CGFloat = 150
        guard maxTotal > 0 else { return 0 }
        return maxH * CGFloat(goal) / CGFloat(maxTotal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(dayStats) { stat in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(stat.total >= goal ? Color.green : Color.blue)
                            .frame(height: barHeight(for: stat.total))
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 150, alignment: .bottom)

                if showGoalLine {
                    Rectangle()
                        .fill(Color.orange)
                        .frame(height: 1)
                        .offset(y: -goalLineHeight())
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 150)

            HStack(spacing: 8) {
                ForEach(dayStats) { stat in
                    Text(dateFormatter.string(from: stat.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            if showGoalLine {
                HStack {
                    Spacer()
                    Text("目标 2000毫升")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct AppPage3SummaryRow: View {
    let dayStat: AppPage3DayStat

    var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f
    }

    var body: some View {
        HStack {
            Text(dateFormatter.string(from: dayStat.date))
                .font(.subheadline)
            Spacer()
            Text("\(dayStat.total) 毫升")
                .bold()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}