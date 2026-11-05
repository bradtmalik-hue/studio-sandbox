import SwiftUI
import Combine

struct AppRootView: View {
    @StateObject private var store = AppFilmStore()

    var body: some View {
        TabView {
            AppQuickLogView()
                .tabItem {
                    Label("记一部", systemImage: "plus.circle.fill")
                }

            AppFilmListView()
                .tabItem {
                    Label("观影列表", systemImage: "list.bullet.rectangle")
                }

            AppStatsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }
        }
        .environmentObject(store)
    }
}