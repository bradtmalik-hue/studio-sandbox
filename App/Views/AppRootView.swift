import SwiftUI
import Foundation

struct AppRootView: View {
    @StateObject private var store = AppFishingStore()
    @State private var selectedTab: Int

    init() {
        _selectedTab = State(initialValue: Self.initialTab())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            AppPage1View()
                .tabItem {
                    Label("记一笔", systemImage: "plus.circle.fill")
                }
                .tag(0)

            AppPage2View(matchesFilter: false)
                .tabItem {
                    Label("收获记录", systemImage: "list.bullet.rectangle")
                }
                .tag(1)

            AppPage3View()
                .tabItem {
                    Label("趋势", systemImage: "chart.bar.xaxis")
                }
                .tag(2)

            AppPage4View(summaries: "")
                .tabItem {
                    Label("钓点", systemImage: "mappin.and.ellipse")
                }
                .tag(3)
        }
        .environmentObject(store)
        .tint(AppTheme.accent)
    }

    private static func initialTab() -> Int {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let value = Int(arguments[index + 1]) {
            return min(max(value, 0), 3)
        }
        #endif
        return 0
    }
}