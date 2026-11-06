import SwiftUI
import Foundation

struct AppRootView: View {
    @StateObject private var store = AppFeedingStore()
    @State private var selectedTab: Int = Self.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                AppFeedingListView()
            }
            .tabItem {
                Label("记录", systemImage: "list.bullet.rectangle")
            }
            .tag(0)

            NavigationStack {
                AppAddFeedingView()
            }
            .tabItem {
                Label("添加", systemImage: "plus.circle.fill")
            }
            .tag(1)

            NavigationStack {
                AppFeedingStatsView()
            }
            .tabItem {
                Label("统计", systemImage: "chart.bar.fill")
            }
            .tag(2)

            NavigationStack {
                AppFeedingSettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
        .environmentObject(store)
        .tint(.orange)
    }

    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-startTab"),
           index + 1 < args.count,
           let value = Int(args[index + 1]) {
            return min(max(value, 0), 3)
        }
        return 0
    }
}