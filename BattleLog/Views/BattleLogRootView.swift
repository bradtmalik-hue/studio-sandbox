import SwiftUI
import Foundation

struct BattleLogRootView: View {
    @StateObject private var store: BattleLogStore
    @State private var selectedTab: Int

    init() {
        DemoSeed.apply()
        _store = StateObject(wrappedValue: BattleLogStore())
        _selectedTab = State(initialValue: BattleLogRootView.initialTab())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                BattleLogListView()
            }
            .tabItem {
                Label("战绩", systemImage: "list.bullet")
            }
            .tag(0)

            NavigationStack {
                BattleLogStatsView()
            }
            .tabItem {
                Label("统计", systemImage: "chart.bar")
            }
            .tag(1)

            NavigationStack {
                AboutBattleLogView()
            }
            .tabItem {
                Label("关于", systemImage: "info.circle")
            }
            .tag(2)
        }
        .preferredColorScheme(.dark)
        .environmentObject(store)
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let value = Int(arguments[index + 1]) {
            return value
        }
        return 0
    }
}

struct AboutBattleLogView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            Text("Battle Log")
                .font(.largeTitle.bold())
            Text("记录你的每一局战绩，分析你的表现。")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Text("所有数据仅保存在本机。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("关于")
    }
}