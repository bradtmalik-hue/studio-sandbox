import SwiftUI
import Foundation

struct AppPage3View: View {
    @EnvironmentObject var store: AppStore
    @State private var displayMode: AppPage3DisplayMode = .chart
    @State private var showInfo = false
    @State private var showGoalEditor = false

    var last7DaysStats: [AppPage3DayStat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        return days.map { day in
            let dayRecords = store.records.filter { calendar.isDate($0.date, inSameDayAs: day) }
            let total = dayRecords.reduce(0) { $0 + $1.amount }
            return AppPage3DayStat(id: day, day: day, total: total, records: dayRecords)
        }
        .sorted { $0.day < $1.day }
    }

    private var averageDaily: Int {
        guard !last7DaysStats.isEmpty else { return 0 }
        let total = last7DaysStats.reduce(0) { $0 + $1.total }
        return total / last7DaysStats.count
    }

    private var achievedDays: Int {
        last7DaysStats.filter { $0.total >= store.dailyGoal }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if last7DaysStats.isEmpty {
                    AppPage3EmptyState()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                AppPage3SummaryCard(
                                    title: "平均每天",
                                    value: averageDaily,
                                    unit: "毫升",
                                    icon: "drop.fill",
                                    color: .blue
                                )
                                AppPage3SummaryCard(
                                    title: "达标天数",
                                    value: achievedDays,
                                    unit: "天",
                                    icon: "checkmark.circle.fill",
                                    color: .green
                                )
                            }
                            .padding(.horizontal)

                            Picker("显示方式", selection: $displayMode) {
                                Text("图表").tag(AppPage3DisplayMode.chart)
                                Text("列表").tag(AppPage3DisplayMode.list)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)

                            if displayMode == .chart {
                                AppPage3BarChart(stats: last7DaysStats, dailyGoal: store.dailyGoal)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(last7DaysStats) { stat in
                                        AppPage3DayRow(stat: stat, dailyGoal: store.dailyGoal)
                                        if stat.id != last7DaysStats.last?.id {
                                            Divider()
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("统计")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showGoalEditor = true
                    } label: {
                        Image(systemName: "target")
                    }
                }
            }
            .alert("统计说明", isPresented: $showInfo) {
                Button("知道了", role: .cancel) { }
            } message: {
                Text("展示最近 7 天的饮水情况，目标为 \(store.dailyGoal) 毫升/天。")
            }
            .sheet(isPresented: $showGoalEditor) {
                AppPage3GoalEditor(goal: $store.dailyGoal) {
                    store.save()
                }
            }
        }
    }
}

private enum AppPage3DisplayMode: Hashable {
    case chart
    case list
}

private struct AppPage3DayStat: Identifiable {
    let id: Date
    let day: Date
    let total: Int
    let records: [AppWaterRecord]
}

private struct AppPage3SummaryCard: View {
    let title: String
    let value: Int
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct AppPage3BarChart: View {
    let stats: [AppPage3DayStat]
    let dailyGoal: Int

    private var maxTotal: Int {
        max(stats.map(\.total).max() ?? 0, dailyGoal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近 7 天")
                .font(.headline)
                .padding(.horizontal)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(stats) { stat in
                    VStack(spacing: 4) {
                        Text("\(stat.total)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Rectangle()
                            .fill(stat.total >= dailyGoal ? Color.green : Color.blue)
                            .frame(width: 24, height: barHeight(for: stat.total))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        Text(dayLabel(for: stat.day))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func barHeight(for total: Int) -> CGFloat {
        guard maxTotal > 0 else { return 0 }
        let ratio = CGFloat(total) / CGFloat(maxTotal)
        return max(4, ratio * 120)
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

private struct AppPage3DayRow: View {
    let stat: AppPage3DayStat
    let dailyGoal: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dayString)
                    .font(.subheadline.weight(.medium))
                Text("\(stat.records.count) 条记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(stat.total) 毫升")
                    .font(.subheadline.weight(.semibold))
                ProgressView(value: min(Double(stat.total) / Double(dailyGoal), 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: stat.total >= dailyGoal ? Color.green : Color.blue))
                    .frame(width: 80)
            }
        }
        .padding(.vertical, 8)
    }

    private var dayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: stat.day)
    }
}

private struct AppPage3EmptyState: View {
    var body: some View {
        ContentUnavailableView {
            Label("暂无饮水记录", systemImage: "drop.triangle")
        } description: {
            Text("请到“今天”页面添加饮水记录，统计信息将在这里显示。")
        }
    }
}

private struct AppPage3GoalEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var goal: Int
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("每日目标") {
                    Stepper(value: $goal, in: 500...5000, step: 250) {
                        HStack {
                            Text("目标")
                            Spacer()
                            Text("\(goal) 毫升")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("调整目标")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(250)])
    }
}