import Foundation
import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppStore()
    @State private var selectedTab = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            AppPage1View(quantity: 0)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            AppPage2View()
                .tabItem { Label("Tanks", systemImage: "aquarium") }
                .tag(1)
            AppPage3View(matchesFilter: false)
                .tabItem { Label("Records", systemImage: "list.bullet.rectangle") }
                .tag(2)
            AppPage4View(items: "")
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
                .tag(3)
        }
        .environmentObject(store)
        .tint(AppTheme.accent)
    }

    private static func initialTab() -> Int {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "-startTab"), idx + 1 < args.count, let tab = Int(args[idx + 1]) {
            return max(0, min(tab, 3))
        }
        #endif
        return 0
    }
}