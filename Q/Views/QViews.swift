import SwiftUI
import Combine

private struct QGeneralHeroCard: View {
    let general: QGeneral

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 44))
                .foregroundStyle(Color.blue)
            VStack(alignment: .leading, spacing: 6) {
                Text(general.name)
                    .font(.title2.bold())
                Text("Q版武将，左右闯关砍小兵")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct QGeneralRow: View {
    let general: QGeneral

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "figure.strengthtraining.traditional")
                .foregroundStyle(Color.blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(general.name)
                    .font(.headline)
                Text("左右移动，出招砍翻小兵")
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

struct QHomeView: View {
    @EnvironmentObject var store: QStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("选一位Q版武将")
                            .font(.largeTitle.bold())
                        Text("左右闯关砍小兵，突破障碍一路向前。")
                            .foregroundStyle(.secondary)
                    }

                    if let first = store.generals.first {
                        NavigationLink(destination: QBattleView()) {
                            QGeneralHeroCard(general: first)
                        }
                        .buttonStyle(.plain)
                    } else {
                        QEmptyStateView()
                    }

                    HStack(spacing: 12) {
                        NavigationLink {
                            QBattleView()
                        } label: {
                            Label("开始闯关", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        NavigationLink {
                            QGeneralLibraryView()
                        } label: {
                            Label("武将库", systemImage: "person.text.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("Q版武将闯关")
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }
}

struct QGeneralLibraryView: View {
    @EnvironmentObject var store: QStore

    var body: some View {
        NavigationStack {
            Group {
                if store.generals.isEmpty {
                    QEmptyStateView()
                } else {
                    List {
                        ForEach(Array(store.generals.enumerated()), id: \.offset) { _, general in
                            NavigationLink(destination: QGeneralDetailView(general: general)) {
                                QGeneralRow(general: general)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("武将库")
        }
    }
}

struct QGeneralDetailView: View {
    let general: QGeneral

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 88))
                    .foregroundStyle(Color.blue)
                Text(general.name)
                    .font(.largeTitle.bold())
                Text("Q版武将，可左右移动，出招砍翻小兵。")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                NavigationLink(destination: QBattleView()) {
                    Label("使用此武将闯关", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle(general.name)
        .navigationBarTitleDisplayMode(.inline)
        .contentMargins(.bottom, 96, for: .scrollContent)
    }
}

struct QBattleView: View {
    var general: QGeneral? = nil
    @EnvironmentObject var store: QStore

    @State private var laneIndex = 3
    @State private var laneEnemies = [
        [true, true, true, true],
        [true, true, true, true],
        [true, true, true, true],
        [true, true, true, true]
    ]
    @State private var score = 0
    @State private var battleMessage = "看准时机，左右移动，出招砍翻小兵。"
    @State private var isVictory = false

    private var activeGeneral: QGeneral? {
        if let general = general { return general }
        return store.generals.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let general = activeGeneral {
                        HStack {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.title2)
                                .foregroundStyle(Color.blue)
                            VStack(alignment: .leading) {
                                Text(general.name)
                                    .font(.title2.bold())
                                Text("Q版武将闯关")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("得分")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(score)")
                                    .font(.title2.bold())
                            }
                        }
                    }

                    VStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { lane in
                            HStack(spacing: 14) {
                                Image(systemName: laneIndex == lane ? "figure.strengthtraining.traditional" : "circle")
                                    .foregroundStyle(laneIndex == lane ? Color.blue : Color.secondary.opacity(0.4))
                                    .frame(width: 30)

                                ForEach(0..<4, id: \.self) { enemyIndex in
                                    let alive = laneEnemies[lane][enemyIndex]
                                    Image(systemName: alive ? "person.fill" : "checkmark.circle.fill")
                                        .foregroundStyle(alive ? Color.red : Color.green)
                                        .font(.title3)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            moveLeft()
                        } label: {
                            Label("左移", systemImage: "arrow.left")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            moveRight()
                        } label: {
                            Label("右移", systemImage: "arrow.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            attack()
                        } label: {
                            Label("出招", systemImage: "flame.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Text(battleMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    if isVictory {
                        Text("闯关成功！")
                            .font(.title2.bold())
                            .foregroundStyle(Color.green)
                    }
                }
                .padding()
            }
            .navigationTitle("闯关")
            .navigationBarTitleDisplayMode(.inline)
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }

    private func moveLeft() {
        withAnimation {
            laneIndex = max(0, laneIndex - 1)
        }
    }

    private func moveRight() {
        withAnimation {
            laneIndex = min(3, laneIndex + 1)
        }
    }

    private func attack() {
        guard !isVictory else { return }

        var attacked = false
        for i in 0..<4 {
            if laneEnemies[laneIndex][i] {
                withAnimation {
                    laneEnemies[laneIndex][i] = false
                }
                score += 1
                attacked = true
                break
            }
        }

        if !attacked {
            battleMessage = "这条道已经清空，换一条道继续。"
        } else {
            battleMessage = "砍翻一个小兵！"
        }

        if laneEnemies.allSatisfy({ row in row.allSatisfy { !$0 } }) {
            battleMessage = "所有小兵都被击破，闯关成功！"
            isVictory = true
        }
    }
}

struct QBattleHistoryView: View {
    @EnvironmentObject var store: QStore

    var body: some View {
        NavigationStack {
            QEmptyStateView()
            .navigationTitle("战报")
        }
    }
}