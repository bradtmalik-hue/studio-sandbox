import SwiftUI
import Foundation

struct BattleLogRootView: View {
    @StateObject private var store: BattleLogStore
    @State private var selectedTab: Int

    init() {
        DemoSeed.apply()
        _store = StateObject(wrappedValue: BattleLogStore())
        _selectedTab = State(initialValue: Self.initialTab())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            BattleLogDashboardView()
                .tabItem {
                    Label("看板", systemImage: "chart.bar.fill")
                }
                .tag(0)

            BattleLogHistoryView()
                .tabItem {
                    Label("历史", systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(1)

            BattleLogAddMatchView()
                .tabItem {
                    Label("添加", systemImage: "plus.circle.fill")
                }
                .tag(2)

            BattleLogStatsView()
                .tabItem {
                    Label("统计", systemImage: "chart.pie.fill")
                }
                .tag(3)
        }
        .environmentObject(store)
        .preferredColorScheme(.dark)
        .tint(Color.accentColor)
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let value = Int(arguments[index + 1]) {
            return min(max(value, 0), 3)
        }
        return 0
    }
}