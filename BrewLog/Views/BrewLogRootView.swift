import SwiftUI
import Combine

struct BrewLogRootView: View {
    @StateObject private var store = BrewLogStore()
    @State private var selectedTab: BrewLogRootTab = .brew

    var body: some View {
        TabView(selection: $selectedTab) {
            BrewLogBrewView()
                .tabItem {
                    Label("冲一杯", systemImage: "cup.and.saucer.fill")
                }
                .tag(BrewLogRootTab.brew)

            BrewLogBeanListView()
                .tabItem {
                    Label("豆单", systemImage: "list.bullet.clipboard.fill")
                }
                .tag(BrewLogRootTab.beans)

            BrewLogStatsView()
                .tabItem {
                    Label("统计", systemImage: "chart.xyaxis.line")
                }
                .tag(BrewLogRootTab.stats)
        }
        .tint(Color(red: 0.75, green: 0.42, blue: 0.18))
        .environmentObject(store)
    }
}

private enum BrewLogRootTab: Hashable {
    case brew
    case beans
    case stats
}