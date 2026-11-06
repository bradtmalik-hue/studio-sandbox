import SwiftUI
import Combine

fileprivate extension BattleResult {
    var isWin: Bool {
        let v = rawValue.lowercased()
        return v.contains("胜") || v == "win" || v == "victory"
    }

    var isLoss: Bool {
        let v = rawValue.lowercased()
        return v.contains("败") || v.contains("负") || v == "loss" || v == "defeat"
    }

    var isDraw: Bool {
        let v = rawValue.lowercased()
        return v.contains("平") || v == "draw" || v == "tie"
    }
}

fileprivate enum BattleLogViewFormatters {
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    static let day: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

struct BattleLogOverviewView: View {
    @EnvironmentObject var store: BattleLogStore
    @State private var showingAddRecord = false

    var sortedRecords: [BattleLogRecord] {
        store.records.sorted { $0.date > $1.date }
    }

    private var recentRecords: [BattleLogRecord] {
        Array(sortedRecords.prefix(5))
    }

    private var totalCount: Int {
        store.records.count
    }

    var winCount: Int {
        store.records.filter { $0.result.isWin }.count
    }

    private var lossCount: Int {
        store.records.filter { $0.result.isLoss }.count
    }

    var drawCount: Int {
        store.records.filter { $0.result.isDraw }.count
    }

    var winRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(winCount) / Double(totalCount)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statsSection
                    recentSection
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 96)
            }
            .background(Color(red: 0.07, green: 0.08, blue: 0.10).ignoresSafeArea())
            .navigationTitle("战绩总览")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddRecord = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("新增战绩")
                }
            }
            .sheet(isPresented: $showingAddRecord) {
                BattleLogAddRecordView()
                    .environmentObject(store)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var statsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            BattleLogStatTile(
                title: "总场次",
                value: "\(totalCount)",
                systemImage: "flag.checkered",
                tint: .cyan
            )
            BattleLogStatTile(
                title: "胜率",
                value: "\(Int((winRate * 100).rounded()))%",
                systemImage: "percent",
                tint: .green
            )
            BattleLogStatTile(
                title: "胜",
                value: "\(winCount)",
                systemImage: "checkmark.circle.fill",
                tint: .green
            )
            BattleLogStatTile(
                title: "负",
                value: "\(lossCount)",
                systemImage: "xmark.circle.fill",
                tint: .red
            )
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近对局")
                .font(.title2.bold())
                .foregroundStyle(.white)

            if recentRecords.isEmpty {
                BattleLogEmptyState(
                    message: "还没有对局记录，点击右上角开始记录",
                    icon: "gamecontroller"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(recentRecords) { record in
                        BattleLogRecordRow(record: record)
                        if record.id != recentRecords.last?.id {
                            Divider()
                                .overlay(Color.white.opacity(0.2))
                        }
                    }
                }
                .padding()
                .background(
                    Color(red: 0.12, green: 0.13, blue: 0.15),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
        }
    }
}

struct BattleLogStatTile: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                    .font(.title3)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            Color(red: 0.12, green: 0.13, blue: 0.15),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
}

struct BattleLogRecordRow: View {
    let record: BattleLogRecord

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.result.rawValue)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(BattleLogViewFormatters.fullDate.string(from: record.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(record.score)")
                .font(.title3.monospacedDigit().bold())
                .foregroundStyle(.white)
        }
        .padding(.vertical, 6)
    }
}

struct BattleLogEmptyState: View {
    let message: String
    let icon: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

private struct BattleLogDayGroup: Identifiable {
    let id: Date
    let date: Date
    let records: [BattleLogRecord]
}

struct BattleLogHistoryView: View {
    @EnvironmentObject var store: BattleLogStore

    private var dayGroups: [BattleLogDayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.records) { record in
            calendar.startOfDay(for: record.date)
        }

        return grouped.map { date, records in
            BattleLogDayGroup(
                id: date,
                date: date,
                records: records.sorted { $0.date > $1.date }
            )
        }
        .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                if store.records.isEmpty {
                    Section {
                        BattleLogEmptyState(
                            message: "还没有战绩，去总览页添加第一局吧",
                            icon: "tray"
                        )
                    }
                    .listRowBackground(Color(red: 0.12, green: 0.13, blue: 0.15))
                } else {
                    ForEach(dayGroups) { group in
                        Section {
                            ForEach(group.records) { record in
                                BattleLogRecordRow(record: record)
                            }
                            .onDelete { offsets in
                                deleteRecords(from: group.records, at: offsets)
                            }
                        } header: {
                            Text(BattleLogViewFormatters.day.string(from: group.date))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(red: 0.07, green: 0.08, blue: 0.10).ignoresSafeArea())
            .navigationTitle("对局历史")
        }
        .preferredColorScheme(.dark)
    }

    private func deleteRecords(from records: [BattleLogRecord], at offsets: IndexSet) {
        let recordsToDelete = offsets.map { records[$0] }
        store.records.removeAll { record in
            recordsToDelete.contains(where: { $0.id == record.id })
        }
        store.save()
    }
}

struct BattleLogAddRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: BattleLogStore

    @State private var date = Date()
    @State private var result: BattleResult = .win
    @State private var score = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("对局信息") {
                    DatePicker(
                        "日期",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    Picker("结果", selection: $result) {
                        ForEach(BattleResult.allCases, id: \.self) { battleResult in
                            Text(battleResult.rawValue)
                                .tag(battleResult)
                        }
                    }

                    Stepper(value: $score, in: 0...999) {
                        HStack {
                            Text("得分")
                            Spacer()
                            Text("\(score)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button("保存记录") {
                        let newRecord = BattleLogRecord(
                            gameName: "未命名",
                            date: date,
                            result: result,
                            score: score
                        )
                        store.records.append(newRecord)
                        store.save()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
                }
            }
            .navigationTitle("新增战绩")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

typealias BattleLogHomeView = BattleLogOverviewView
typealias BattleLogSummaryView = BattleLogOverviewView
typealias BattleLogMatchesView = BattleLogHistoryView
typealias BattleLogRecordsView = BattleLogHistoryView
typealias BattleLogNewRecordView = BattleLogAddRecordView
typealias BattleLogAddView = BattleLogAddRecordView