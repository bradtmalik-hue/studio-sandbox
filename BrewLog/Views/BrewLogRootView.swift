import SwiftUI

struct BrewLogRootView: View {
    @StateObject private var store = BrewLogStore()

    var body: some View {
        TabView {
            BrewLogSessionView()
                .tabItem {
                    Label("冲一杯", systemImage: "cup.and.saucer.fill")
                }

            BrewLogBeanListView()
                .tabItem {
                    Label("豆单", systemImage: "list.bullet.clipboard")
                }

            BrewLogStatsView()
                .tabItem {
                    Label("统计", systemImage: "chart.xyaxis.line")
                }
        }
        .tint(.orange)
        .environmentObject(store)
    }
}

#Preview {
    BrewLogRootView()
}