import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppGrowthStore()
    @State private var selectedTab = AppRootView.initialTab()

    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-startTab"), index + 1 < args.count, let tab = Int(args[index + 1]) {
            return tab
        }
        return 0
    }

    private static let accentColor = Color(red: 0.05, green: 0.35, blue: 0.25)

    var body: some View {
        TabView(selection: $selectedTab) {
            AppEntryFormView()
                .tabItem {
                    Label("记一笔", systemImage: "plus.circle.fill")
                }
                .tag(0)

            AppGrowthChartView()
                .tabItem {
                    Label("曲线", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)

            AppHistoryView()
                .tabItem {
                    Label("历史", systemImage: "list.bullet.rectangle")
                }
                .tag(2)

            AppCalendarView()
                .tabItem {
                    Label("日历", systemImage: "calendar")
                }
                .tag(3)
        }
        .tint(AppRootView.accentColor)
        .environmentObject(store)
    }
}