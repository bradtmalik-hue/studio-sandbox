import SwiftUI

struct LoopRootView: View {
    @StateObject private var store = LoopStore()
    @State private var selectedTab: Int = LoopRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            LoopMomentsView()
                .tabItem {
                    Label("Moments", systemImage: "list.bullet.rectangle")
                }
                .tag(0)

            LoopAddMomentView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(1)

            LoopSummaryView()
                .tabItem {
                    Label("Summary", systemImage: "chart.bar.xaxis")
                }
                .tag(2)
        }
        .environmentObject(store)
    }

    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "-startTab"), idx + 1 < args.count, let tab = Int(args[idx + 1]) {
            return tab
        }
        return 0
    }
}