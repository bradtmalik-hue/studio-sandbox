import SwiftUI
import Foundation

// MARK: - BattleResult 扩展
extension BattleResult {
    var displayName: String {
        switch self {
        case .win: return "胜利"
        case .lose: return "失败"
        case .draw: return "平局"
        }
    }

    var color: Color {
        switch self {
        case .win: return .green
        case .lose: return .red
        case .draw: return .orange
        }
    }
}

// MARK: - BattleLogStore 扩展：提供便捷方法
extension BattleLogStore {
    func addBattleRecord(gameName: String, date: Date, result: BattleResult, kills: Int, deaths: Int, assists: Int, notes: String) {
        let record = BattleRecord(gameName: gameName, date: date, result: result, kills: kills, deaths: deaths, assists: assists, notes: notes)
        records.append(record)
        persistRecords()
    }

    func updateBattleRecord(id: UUID, gameName: String, date: Date, result: BattleResult, kills: Int, deaths: Int, assists: Int, notes: String) {
        if let index = records.firstIndex(where: { $0.id == id }) {
            records[index].gameName = gameName
            records[index].date = date
            records[index].result = result
            records[index].kills = kills
            records[index].deaths = deaths
            records[index].assists = assists
            records[index].notes = notes
            persistRecords()
        }
    }

    func deleteBattleRecord(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        persistRecords()
    }

    private func persistRecords() {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("battleLogRecords.json")
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL)
        } catch {
            print("保存失败: \(error)")
        }
    }
}

// MARK: - 列表页
struct BattleLogListView: View {
    @EnvironmentObject var store: BattleLogStore
    @State private var showingAdd = false
    @State private var selectedRecord: BattleRecord?

    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    BattleLogEmptyView()
                } else {
                    list
                }
            }
            .navigationTitle("战绩记录")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("添加战绩")
                }
            }
            .sheet(isPresented: $showingAdd) {
                BattleLogEditView(record: nil)
                    .environmentObject(store)
            }
            .sheet(item: $selectedRecord) { record in
                BattleLogEditView(record: record)
                    .environmentObject(store)
            }
        }
        .preferredColorScheme(.dark)
    }

    var list: some View {
        List {
            ForEach(store.records) { record in
                Button {
                    selectedRecord = record
                } label: {
                    BattleLogRow(record: record)
                }
            }
            .onDelete(perform: delete)
        }
        .listStyle(.insetGrouped)
    }

    func delete(at offsets: IndexSet) {
        store.deleteBattleRecord(at: offsets)
    }
}

// MARK: - 空状态
struct BattleLogEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("还没有战绩记录")
                .font(.title2)
                .fontWeight(.semibold)
            Text("点击右上角 + 添加第一局战绩")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - 行视图
struct BattleLogRow: View {
    let record: BattleRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.gameName)
                    .font(.headline)
                Text(record.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(record.result.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(record.result.color)
                Text("\(record.kills)/\(record.deaths)/\(record.assists)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 编辑/添加页
struct BattleLogEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: BattleLogStore

    let record: BattleRecord?

    @State private var gameName: String
    @State private var date: Date
    @State private var result: BattleResult
    @State private var kills: Int
    @State private var deaths: Int
    @State private var assists: Int
    @State private var notes: String

    init(record: BattleRecord?) {
        self.record = record
        _gameName = State(initialValue: record?.gameName ?? "")
        _date = State(initialValue: record?.date ?? Date())
        _result = State(initialValue: record?.result ?? .win)
        _kills = State(initialValue: record?.kills ?? 0)
        _deaths = State(initialValue: record?.deaths ?? 0)
        _assists = State(initialValue: record?.assists ?? 0)
        _notes = State(initialValue: record?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("游戏名称") {
                    TextField("例如：英雄联盟", text: $gameName)
                }
                Section("日期") {
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }
                Section("结果") {
                    Picker("结果", selection: $result) {
                        ForEach(BattleResult.allCases, id: \.self) { r in
                            Text(r.displayName).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("数据") {
                    Stepper("击杀: \(kills)", value: $kills)
                    Stepper("死亡: \(deaths)", value: $deaths)
                    Stepper("助攻: \(assists)", value: $assists)
                }
                Section("备注") {
                    TextField("可选备注", text: $notes)
                }
            }
            .navigationTitle(record == nil ? "添加战绩" : "编辑战绩")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(gameName.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    func save() {
        if let record = record {
            store.updateBattleRecord(id: record.id, gameName: gameName, date: date, result: result, kills: kills, deaths: deaths, assists: assists, notes: notes)
        } else {
            store.addBattleRecord(gameName: gameName, date: date, result: result, kills: kills, deaths: deaths, assists: assists, notes: notes)
        }
        dismiss()
    }
}

// MARK: - 统计页
struct BattleLogStatsView: View {
    @EnvironmentObject var store: BattleLogStore

    var totalGames: Int { store.records.count }
    private var winCount: Int { store.records.filter { $0.result == .win }.count }
    var winRate: Double { totalGames > 0 ? Double(winCount) / Double(totalGames) : 0 }

    private var totalKills: Int { store.records.reduce(0) { $0 + $1.kills } }
    private var totalDeaths: Int { store.records.reduce(0) { $0 + $1.deaths } }
    private var totalAssists: Int { store.records.reduce(0) { $0 + $1.assists } }
    private var kda: Double {
        if totalDeaths == 0 { return Double(totalKills + totalAssists) }
        return Double(totalKills + totalAssists) / Double(totalDeaths)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        BattleLogStatCard(title: "总场次", value: "\(totalGames)", systemImage: "gamecontroller")
                        BattleLogStatCard(title: "胜率", value: "\(Int(winRate * 100))%", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    HStack(spacing: 16) {
                        BattleLogStatCard(title: "总击杀", value: "\(totalKills)", systemImage: "scope")
                        BattleLogStatCard(title: "总死亡", value: "\(totalDeaths)", systemImage: "heart.slash")
                    }
                    HStack(spacing: 16) {
                        BattleLogStatCard(title: "总助攻", value: "\(totalAssists)", systemImage: "hands.sparkles")
                        BattleLogStatCard(title: "KDA", value: String(format: "%.2f", kda), systemImage: "person.3")
                    }
                }
                .padding()
            }
            .navigationTitle("统计")
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - 统计卡片
struct BattleLogStatCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}