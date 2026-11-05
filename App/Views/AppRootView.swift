import SwiftUI

struct AppRootView: View {
    private enum AppRootTab: Hashable {
        case entry
        case chart
        case history
    }

    @StateObject private var store = AppGrowthStore()
    @State private var selection: AppRootTab = .entry

    var body: some View {
        TabView(selection: $selection) {
            AppEntryView()
                .tabItem {
                    Label("记一笔", systemImage: "plus.circle.fill")
                }
                .tag(AppRootTab.entry)

            AppGrowthChartView()
                .tabItem {
                    Label("成长曲线", systemImage: "chart.xyaxis.line")
                }
                .tag(AppRootTab.chart)

            AppHistoryView()
                .tabItem {
                    Label("历史记录", systemImage: "list.bullet.rectangle")
                }
                .tag(AppRootTab.history)
        }
        .environmentObject(store)
        .tint(.blue)
        .preferredColorScheme(.light)
    }
}