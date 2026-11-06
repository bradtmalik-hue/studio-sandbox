import SwiftUI
import Foundation

struct BattleLogRootView: View {
    @StateObject private var store = BattleLogStore()
    @State private var selectedTab: Int = BattleLogRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            BattleLogOverviewView(store: store)
                .tabItem {
                    Label("概览", systemImage: "chart.bar.xaxis")
                }
                .tag(0)

            BattleLogHistoryView()
                .tabItem {
                    Label("历史", systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(1)

            BattleLogAddRecordView()
                .tabItem {
                    Label("新增", systemImage: "plus.circle.fill")
                }
                .tag(2)
        }
        .environmentObject(store)
        .preferredColorScheme(.dark)
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let value = Int(arguments[index + 1]) {
            return min(max(value, 0), 2)
        }
        return 0
    }
}

#Preview {
    BattleLogRootView()
}