import SwiftUI
import Foundation

struct AppRootView: View {
    @StateObject private var store = AppHydrationStore()
    @State private var selectedTab = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            AppPage1View(store: store, filter: .all, selectedRecord: nil, goal: 2000)
                .tabItem {
                    Label("今天", systemImage: "drop.fill")
                }
                .tag(0)

            AppPage2View(store: store, filter: .all, selectedRecord: nil)
                .tabItem {
                    Label("历史", systemImage: "calendar")
                }
                .tag(1)

            AppPage3View(store: store, selectedDays: 7)
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }
                .tag(2)
        }
        .environmentObject(store)
        .tint(.teal)
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