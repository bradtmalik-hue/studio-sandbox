import SwiftUI
import Foundation

// MARK: - 武将列表
struct QHeroListView: View {
    @EnvironmentObject var store: QGameStore

    var body: some View {
        NavigationStack {
            List {
                if store.heroes.isEmpty {
                    ContentUnavailableView(
                        "暂无武将",
                        systemImage: "figure.star",
                        description: Text("点击「闯关」开始游戏，或使用 -demoData 启动生成演示数据")
                    )
                } else {
                    Section {
                        ForEach(store.heroes) { hero in
                            QHeroRow(hero: hero)
                        }
                    } header: {
                        Text("可选武将")
                    } footer: {
                        Text("在「闯关」页选择武将和关卡后开始战斗")
                    }
                }

                Section {
                    Color.clear.frame(height: 96)
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("武将")
        }
    }
}

private struct QHeroRow: View {
    let hero: QHero

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: heroSymbolName(for: hero.name))
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 48, height: 48)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(hero.name)
                    .font(.headline)
                Text("Q版武将")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 闯关选择
struct QLevelSelectView: View {
    @EnvironmentObject var store: QGameStore
    @State private var selectedHeroID: UUID?

    var body: some View {
        NavigationStack {
            List {
                if store.heroes.isEmpty {
                    ContentUnavailableView(
                        "暂无武将",
                        systemImage: "figure.star",
                        description: Text("请先添加武将或在启动参数中加入 -demoData")
                    )
                } else {
                    Section {
                        ForEach(store.heroes) { hero in
                            Button {
                                selectedHeroID = hero.id
                            } label: {
                                HStack {
                                    Image(systemName: heroSymbolName(for: hero.name))
                                        .foregroundStyle(.tint)
                                    Text(hero.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedHeroID == hero.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.tint)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("1. 选择武将")
                    }

                    if let hero = selectedHero {
                        Section {
                            if store.levels.isEmpty {
                                ContentUnavailableView(
                                    "暂无关卡",
                                    systemImage: "flag",
                                    description: Text("使用 -demoData 启动生成演示关卡")
                                )
                            } else {
                                ForEach(store.levels) { level in
                                    NavigationLink {
                                        QBattleView(hero: hero, level: level)
                                    } label: {
                                        QLevelRow(level: level)
                                    }
                                }
                            }
                        } header: {
                            Text("2. 选择关卡")
                        } footer: {
                            Text("推荐从低难度关卡开始挑战")
                        }
                    } else {
                        Section {
                            Text("请先选择一名武将")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Color.clear.frame(height: 96)
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("闯关")
            .onAppear {
                if selectedHeroID == nil {
                    selectedHeroID = store.heroes.first?.id
                }
            }
        }
    }

    private var selectedHero: QHero? {
        guard let selectedHeroID else { return nil }
        return store.heroes.first(where: { $0.id == selectedHeroID })
    }
}

private struct QLevelRow: View {
    let level: QLevel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "flag.fill")
                .foregroundStyle(.orange)
                .frame(width: 32, height: 32)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(level.name)
                    .font(.headline)
                Text("横版闯关")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 战斗模拟
struct QBattleView: View {
    @EnvironmentObject var store: QGameStore

    let hero: QHero
    let level: QLevel

    @State private var phase: QBattlePhase = .ready
    @State private var progress: Double = 0
    @State private var starsEarned: Int = 0
    @State private var finalScore: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                battleHeader

                switch phase {
                case .ready:
                    readyPanel
                case .running:
                    runningPanel
                case .finished:
                    resultPanel
                }
            }
            .padding()
        }
        .navigationTitle("\(hero.name) · \(level.name)")
    }

    private var battleHeader: some View {
        HStack(spacing: 14) {
            Image(systemName: heroSymbolName(for: hero.name))
                .font(.largeTitle)
                .foregroundStyle(.tint)
                .frame(width: 64, height: 64)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 6) {
                Text(hero.name)
                    .font(.title3.bold())
                Text("关卡：\(level.name)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var readyPanel: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("准备战斗")
                .font(.headline)

            Text("你将操控 \(hero.name)，在横版关卡中闪避障碍并击败沿途小兵。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                startBattle()
            } label: {
                Label("开始闯关", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var runningPanel: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.blue)

            Text("战斗中...")
                .font(.headline)

            Text("闪避、出招，一路砍过去！")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var resultPanel: some View {
        VStack(spacing: 18) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < starsEarned ? "star.fill" : "star")
                        .font(.largeTitle)
                        .foregroundStyle(index < starsEarned ? .yellow : .secondary)
                }
            }

            Text("结算")
                .font(.title2.bold())

            HStack {
                VStack(spacing: 4) {
                    Text("得分")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(finalScore)")
                        .font(.title3.bold())
                }

                Spacer()

                VStack(spacing: 4) {
                    Text("用时")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int.random(in: 18...48))秒")
                        .font(.title3.bold())
                }
            }
            .padding(.horizontal)

            Text("本场战绩已保存，可从「战绩」页查看。")
                .font(.footnote)
                .foregroundStyle(.secondary)

            NavigationLink {
                QBattleRecordsView()
            } label: {
                Text("查看战绩")
                    .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func startBattle() {
        phase = .running
        progress = 0

        Task {
            for step in 1...12 {
                try? await Task.sleep(nanoseconds: 160_000_000)
                progress = Double(step) / 12.0
            }
            finishBattle()
        }
    }

    private func finishBattle() {
        starsEarned = Int.random(in: 1...3)
        finalScore = starsEarned * 1000 + Int.random(in: 50...999)

        let record = QBattleRecord(
            date: Date(),
            heroName: hero.name,
            levelName: level.name,
            stars: starsEarned,
            score: finalScore,
            durationSeconds: Int.random(in: 18...48)
        )

        store.records.append(record)
        store.save()
        phase = .finished
        progress = 1.0
    }
}

// MARK: - 战绩
struct QBattleRecordsView: View {
    @EnvironmentObject var store: QGameStore

    var body: some View {
        NavigationStack {
            List {
                if store.records.isEmpty {
                    ContentUnavailableView(
                        "暂无战绩",
                        systemImage: "list.star",
                        description: Text("完成一场战斗后，战绩会显示在这里")
                    )
                } else {
                    Section {
                        HStack {
                            Text("总场次")
                            Spacer()
                            Text("\(store.records.count)")
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("平均星级")
                            Spacer()
                            Text(averageStarsText)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section {
                        ForEach(sortedRecords) { record in
                            QBattleRecordRow(record: record)
                        }
                    } header: {
                        Text("最近战斗")
                    }
                }

                Section {
                    Color.clear.frame(height: 96)
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("战绩")
        }
    }

    private var sortedRecords: [QBattleRecord] {
        store.records.sorted { $0.date > $1.date }
    }

    private var averageStarsText: String {
        guard !store.records.isEmpty else { return "0.0" }
        let total = store.records.reduce(0) { $0 + $1.stars }
        return String(format: "%.1f", Double(total) / Double(store.records.count))
    }
}

private struct QBattleRecordRow: View {
    let record: QBattleRecord

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("\(record.heroName) · \(record.levelName)")
                    .font(.headline)
                Text(recordDateFormatter.string(from: record.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < record.stars ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(index < record.stars ? .yellow : .secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 工具
private enum QBattlePhase {
    case ready
    case running
    case finished
}

private let recordDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M月d日 HH:mm"
    return formatter
}()

private func heroSymbolName(for heroName: String) -> String {
    switch heroName {
    case "赵云":
        return "flame.fill"
    case "关羽":
        return "shield.fill"
    case "张飞":
        return "bolt.fill"
    case "诸葛亮":
        return "sparkles"
    case "曹操":
        return "crown.fill"
    case "吕布":
        return "arrow.up.circle.fill"
    case "孙尚香":
        return "heart.fill"
    default:
        return "figure.star"
    }
}