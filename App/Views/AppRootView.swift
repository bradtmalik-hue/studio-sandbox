import SwiftUI
import Combine

struct AppRootView: View {
    @StateObject private var store = AppGrowthStore()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            AppEntryFormView(store: store)
                .tabItem {
                    Label("记一笔", systemImage: "plus.circle.fill")
                }
                .tag(0)

            GrowthCurveView(store: store)
                .tabItem {
                    Label("成长曲线", systemImage: "chart.xyaxis.line")
                }
                .tag(1)

            HistoryListView(store: store)
                .tabItem {
                    Label("历史记录", systemImage: "list.bullet.rectangle")
                }
                .tag(2)
        }
        .environmentObject(store)
        .tint(Color.blue)
        .preferredColorScheme(.light)
    }
}