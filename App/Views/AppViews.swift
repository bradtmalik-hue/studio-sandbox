import SwiftUI
import Foundation

struct AppAddRunView: View {
    @EnvironmentObject var store: AppRunStore

    @State private var date = Date()
    @State private var distanceText = ""
    @State private var durationMinutes = ""
    @State private var durationSeconds = ""
    @State private var notes = ""
    @State private var showingSavedAlert = false
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("训练信息") {
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                    HStack {
                        Text("距离 (公里)")
                        Spacer()
                        TextField("0.0", text: $distanceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("时长")
                        Spacer()
                        TextField("分钟", text: $durationMinutes)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                        Text("分")
                        TextField("秒", text: $durationSeconds)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                        Text("秒")
                    }
                    TextField("备注 (可选)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section {
                    Button("保存这次跑步") {
                        saveRun()
                    }
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
                }
                .disabled(distanceText.isEmpty && durationMinutes.isEmpty && durationSeconds.isEmpty)
            }
            .navigationTitle("记一次跑")
            .alert("已保存", isPresented: $showingSavedAlert) {
                Button("好", role: .cancel) { }
            } message: {
                Text("这次跑步已经记录好了。")
            }
            .alert("信息不完整", isPresented: $showingValidationAlert) {
                Button("好", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }

    private func saveRun() {
        guard let distance = Double(distanceText.replacingOccurrences(of: ",", with: ".")), distance > 0 else {
            validationMessage = "请输入有效的跑步距离。"
            showingValidationAlert = true
            return
        }
        let minutes = Int(durationMinutes) ?? 0
        let seconds = Int(durationSeconds) ?? 0
        let totalSeconds = max(0, minutes * 60 + seconds)
        guard totalSeconds > 0 else {
            validationMessage = "请输入跑步时长。"
            showingValidationAlert = true
            return
        }
        store.addRun(date: date, distanceKm: distance, durationMinutes: Double(totalSeconds) / 60.0, note: notes)
        distanceText = ""
        durationMinutes = ""
        durationSeconds = ""
        notes = ""
        showingSavedAlert = true
    }
}

struct AppRunLogView: View {
    @EnvironmentObject var store: AppRunStore

    var body: some View {
        NavigationStack {
            Group {
                if store.runs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("还没有跑步记录")
                            .font(.headline)
                        Text("去“记一次跑”添加你的第一次跑步吧")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(store.runs.sorted(by: { $0.date > $1.date }), id: \.id) { run in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(run.date, style: .date)
                                        .font(.headline)
                                    Text(run.date, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(String(format: "%.2f 公里", run.distanceKm))
                                        .font(.headline)
                                    Text(formatDuration(run.durationMinutes * 60))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteRuns)
                    }
                }
            }
            .navigationTitle("跑步记录")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(store.runs.count) 次")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func deleteRuns(at offsets: IndexSet) {
        let sortedRuns = store.runs.sorted(by: { $0.date > $1.date })
        let runsToDelete = offsets.map { sortedRuns[$0] }
        for run in runsToDelete {
            store.deleteRun(run)
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct AppWeeklyVolumeView: View {
    @EnvironmentObject var store: AppRunStore

    var body: some View {
        NavigationStack {
            Group {
                if store.runs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("暂无周跑量数据")
                            .font(.headline)
                        Text("先记录几次跑步，这里会显示最近八周的跑量趋势")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("最近八周跑量")
                                .font(.title2)
                                .fontWeight(.semibold)
                            weeklyChart
                            weeklySummary
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("周跑量趋势")
        }
    }

    private var weeklyChart: some View {
        let weeks = lastEightWeeks()
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(weeks, id: \.weekStart) { week in
                    VStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(barColor(for: week.volumeKm))
                            .frame(height: barHeight(for: week.volumeKm, maxValue: maxDistance(in: weeks)))
                        Text(weekLabel(week.weekStart))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var weeklySummary: some View {
        let weeks = lastEightWeeks()
        let total = weeks.reduce(0.0) { $0 + $1.volumeKm }
        let average = weeks.isEmpty ? 0 : total / Double(weeks.count)
        return HStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("总跑量")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f 公里", total))
                    .font(.headline)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("平均每周")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f 公里", average))
                    .font(.headline)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func lastEightWeeks() -> [AppWeeklyVolume] {
        let calendar = Calendar.current
        let today = Date()
        guard let eightWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -7, to: today) else { return [] }
        var result: [AppWeeklyVolume] = []
        for weekOffset in 0..<8 {
            if let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today),
               let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: weekStart)?.start {
                let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? startOfWeek
                let volumeKm = store.runs
                    .filter { $0.date >= startOfWeek && $0.date <= endOfWeek }
                    .reduce(0.0) { $0 + $1.distanceKm }
                result.append(AppWeeklyVolume(weekStart: startOfWeek, volumeKm: volumeKm))
            }
        }
        return result.sorted { $0.weekStart < $1.weekStart }
    }

    private func maxDistance(in weeks: [AppWeeklyVolume]) -> Double {
        weeks.map(\.volumeKm).max() ?? 1
    }

    private func barHeight(for value: Double, maxValue: Double) -> CGFloat {
        let ratio = maxValue > 0 ? value / maxValue : 0
        return max(10, CGFloat(ratio) * 160)
    }

    private func barColor(for value: Double) -> Color {
        if value == 0 { return Color(.systemGray4) }
        return Color.primary
    }

    private func weekLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}