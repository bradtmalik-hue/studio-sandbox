import Foundation
import SwiftUI

struct QRootView: View {
    @State private var selectedTab: Int = QRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                QHeroListView()
                    .navigationTitle("选择武将")
            }
            .tabItem {
                Label("武将", systemImage: "person.3.fill")
            }
            .tag(0)

            NavigationStack {
                QLevelSelectView()
                    .navigationTitle("选择关卡")
            }
            .tabItem {
                Label("关卡", systemImage: "flag.checkered")
            }
            .tag(1)

            NavigationStack {
                QBattleView()
                    .navigationTitle("战斗")
            }
            .tabItem {
                Label("战斗", systemImage: "gamecontroller.fill")
            }
            .tag(2)

            NavigationStack {
                QBattleRecordsView()
                    .navigationTitle("战绩")
            }
            .tabItem {
                Label("战绩", systemImage: "trophy.fill")
            }
            .tag(3)
        }
    }

    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-startTab"), i + 1 < args.count, let v = Int(args[i + 1]) {
            return min(max(v, 0), 3)
        }
        return 0
    }
}