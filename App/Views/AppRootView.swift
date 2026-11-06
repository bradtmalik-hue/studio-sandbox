import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppGrowthStore()
    @State private var selectedTab = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            AppDashboardView()
                .tabItem {
                    Label("记录", systemImage: "list.bullet.rectangle")
                }
                .tag(0)

            AppGrowthChartView()
                .tabItem {
                    Label("曲线", systemImage: "chart.xyaxis.line")
                }
                .tag(1)

            AppMonthlyStatsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }
                .tag(2)
        }
        .environmentObject(store)
        .tint(.teal)
        .preferredColorScheme(.light)
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