import SwiftUI
import Foundation

struct AppRootView: View {
    @StateObject private var store = AppCatMealStore()
    @State private var selectedTab: Int = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            AppFeedingLogView()
                .tabItem {
                    Label("喂养", systemImage: "fork.knife")
                }
                .tag(0)

            AppFeedingCalendarView()
                .tabItem {
                    Label("日历", systemImage: "calendar")
                }
                .tag(1)

            AppFeedingSummaryView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.xaxis")
                }
                .tag(2)
        }
        .environmentObject(store)
        .tint(.orange)
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let tab = Int(arguments[index + 1]) {
            return min(max(tab, 0), 2)
        }
        return 0
    }
}