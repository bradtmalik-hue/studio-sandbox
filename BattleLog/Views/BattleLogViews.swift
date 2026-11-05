import SwiftUI
import Foundation

private extension Color {
    static let battleLogBackground = Color(red: 0.07, green: 0.08, blue: 0.10)
    static let battleLogCard = Color(red: 0.12, green: 0.13, blue: 0.15)
}

private func resultShortName(_ result: BattleLogResult) -> String {
    switch result {
    case .win: return "胜"
    case .loss: return "负"
    case .draw: return "平"
    }
}

private func resultDisplayName(_ result: BattleLogResult) -> String {
    switch result {
    case .win: return "胜利"
    case .loss: return "失败"
    case .draw: return "平局"
    }
}

private func resultColor(_ result: BattleLogResult) -> Color {
    switch result {
    case .win: return .green
    case .loss: return .red
    case .draw: return .orange
    }
}

struct BattleLogDashboardView: View {
    @EnvironmentObject var store: BattleLogStore
    @State private var showingAdd = false

    private var totalMatches: Int {
        store.matches.count
    }

    private var winRate: Double {
        guard totalMatches > 0 else { return 0 }
        let wins = store.matches.filter { $0.result == .win }.count
        return Double(wins) / Double(totalMatches)
    }

    private var totalScore: Int {
        store.matches.reduce(0) { $0 + $1.score }
    }

    private var recentMatches: [BattleLogMatch] {
        Array(store.matches.suffix(5).reversed())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.battleLogBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        HStack(spacing: 12) {
                            StatCard(title: "总对局", value: "\(totalMatches)", color: .white)
                            StatCard(title: "胜率", value: String(format: "%.0f%%", winRate * 100), color: .green)
                        }

                        HStack(spacing: 12) {
                            StatCard(title: "累计得分", value: "\(totalScore)", color: .orange)
                            StatCard(title: "最近状态", value: recentFormText, color: .blue)
                        }

                        if store.matches.isEmpty {
                            ContentUnavailableView(
                                "还没有战绩",
                                systemImage: "gamecontroller.fill",
                                description: Text("点击右上角 + 记录第一局游戏结果")
                            )
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("最近对局")
                                    .font(.headline)

                                ForEach(recentMatches) { match in
                                    BattleLogMatchRowView(match: match)
                                }
                            }
                        }

                        Button {
                            showingAdd = true
                        } label: {
                            Label("新增战绩", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("战况总览")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                BattleLogAddMatchView()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var recentFormText: String {
        guard !recentMatches.isEmpty else { return "暂无" }
        let wins = recentMatches.filter { $0.result == .win }.count
        return "\(wins)胜\(recentMatches.count - wins)负"
    }
}

struct BattleLogHistoryView: View {
    @EnvironmentObject var store: BattleLogStore
    @State private var filter: BattleLogResult?

    private var filteredMatches: [BattleLogMatch] {
        guard let filter else { return store.matches }
        return store.matches.filter { $0.result == filter }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.battleLogBackground.ignoresSafeArea()

                if store.matches.isEmpty {
                    ContentUnavailableView(
                        "还没有战绩",
                        systemImage: "list.bullet.clipboard",
                        description: Text("新增一局后，这里会按时间列出所有对局")
                    )
                } else {
                    List {
                        Picker("筛选结果", selection: $filter) {
                            Text("全部").tag(nil as BattleLogResult?)
                            ForEach([BattleLogResult.win, .loss, .draw], id: \.self) { result in
                                Text(resultDisplayName(result)).tag(result as BattleLogResult?)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)

                        ForEach(filteredMatches) { match in
                            BattleLogMatchRowView(match: match)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("对局记录")
        }
        .preferredColorScheme(.dark)
    }
}

struct BattleLogAddMatchView: View {
    @EnvironmentObject var store: BattleLogStore
    @Environment(\.dismiss) var dismiss

    @State private var result: BattleLogResult = .win
    @State private var scoreText = ""
    @State private var opponent = ""
    @State private var date = Date()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.battleLogBackground.ignoresSafeArea()

                Form {
                    Picker("结果", selection: $result) {
                        ForEach([BattleLogResult.win, .loss, .draw], id: \.self) { result in
                            Text(resultDisplayName(result)).tag(result)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("我方得分", text: $scoreText)
                        .keyboardType(.numberPad)

                    TextField("对手名称", text: $opponent)

                    DatePicker("日期", selection: $date, displayedComponents: .date)

                    TextField("备注（可选）", text: $notes, axis: .vertical)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("新增战绩")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveMatch()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var isFormValid: Bool {
        guard let score = Int(scoreText), score >= 0 else { return false }
        return !opponent.isEmpty
    }

    private func saveMatch() {
        guard let score = Int(scoreText), !opponent.isEmpty else { return }
        let match = BattleLogMatch(date: date, result: result, score: score, opponent: opponent, notes: notes)
        store.add(match)
        dismiss()
    }
}

struct BattleLogStatsView: View {
    @EnvironmentObject var store: BattleLogStore

    private var total: Int {
        store.matches.count
    }

    private var wins: Int {
        store.matches.filter { $0.result == .win }.count
    }

    private var losses: Int {
        store.matches.filter { $0.result == .loss }.count
    }

    private var draws: Int {
        store.matches.filter { $0.result == .draw }.count
    }

    private var winRate: Double {
        guard total > 0 else { return 0 }
        return Double(wins) / Double(total)
    }

    private var averageScore: Double {
        guard total > 0 else { return 0 }
        let sum = store.matches.reduce(0) { $0 + $1.score }
        return Double(sum) / Double(total)
    }

    private var bestScore: Int {
        store.matches.map(\.score).max() ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.battleLogBackground.ignoresSafeArea()

                if store.matches.isEmpty {
                    ContentUnavailableView(
                        "暂无统计数据",
                        systemImage: "chart.bar.xaxis",
                        description: Text("新增几局战绩后，这里会展示胜率和表现趋势")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            StatCard(
                                title: "总胜率",
                                value: String(format: "%.0f%%", winRate * 100),
                                color: .green
                            )

                            HStack(spacing: 12) {
                                StatCard(title: "胜", value: "\(wins)", color: .green)
                                StatCard(title: "负", value: "\(losses)", color: .red)
                                StatCard(title: "平", value: "\(draws)", color: .orange)
                            }

                            StatCard(
                                title: "平均得分",
                                value: String(format: "%.1f", averageScore),
                                color: .blue
                            )

                            StatCard(
                                title: "最高得分",
                                value: "\(bestScore)",
                                color: .purple
                            )

                            winRateBar
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("表现趋势")
        }
        .preferredColorScheme(.dark)
    }

    private var winRateBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("胜率进度")
                .font(.caption)
                .foregroundStyle(.secondary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * winRate)
                }
            }
            .frame(height: 12)
        }
    }
}

struct BattleLogMatchRowView: View {
    let match: BattleLogMatch

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(resultColor(match.result).opacity(0.18))
                .frame(width: 46, height: 46)
                .overlay(
                    Text(resultShortName(match.result))
                        .font(.headline)
                        .foregroundStyle(resultColor(match.result))
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(match.opponent.isEmpty ? "未命名对手" : match.opponent)
                    .font(.headline)

                Text(match.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text("\(match.score)")
                    .font(.title3.bold())

                Text(resultDisplayName(match.result))
                    .font(.caption)
                    .foregroundStyle(resultColor(match.result))
            }
        }
        .padding()
        .background(Color.battleLogCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.battleLogCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}