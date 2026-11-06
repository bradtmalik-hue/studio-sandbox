import SwiftUI
import Foundation

struct AppRootView: View {
    @State private var selectedTab: Int

    init(selectedTab: Int = AppRootView.initialTab()) {
        _selectedTab = State(initialValue: selectedTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            PlaceholderView()
                .tabItem {
                    Label("今日", systemImage: "sun.max.fill")
                }
                .tag(0)

            PlaceholderView()
                .tabItem {
                    Label("历史", systemImage: "calendar")
                }
                .tag(1)

            PlaceholderView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }
                .tag(2)
        }
        .tint(.orange)
    }

    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-startTab"),
           index + 1 < args.count,
           let value = Int(args[index + 1]) {
            return min(max(value, 0), 2)
        }
        return 0
    }
}