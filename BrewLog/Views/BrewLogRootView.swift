import SwiftUI

struct BrewLogRootView: View {
    @StateObject private var store = BrewLogStore()

    var body: some View {
        TabView {
            BrewSessionView()
                .tabItem {
                    Label("冲一杯", systemImage: "cup.and.saucer.fill")
                }

            BeanListView()
                .tabItem {
                    Label("豆单", systemImage: "list.bullet")
                }

            StatsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }
        }
        .environmentObject(store)
        .tint(.orange)
    }
}

#Preview {
    BrewLogRootView()
}