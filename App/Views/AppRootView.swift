import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppGrowthStore()

    var body: some View {
        TabView {
            AppRecordEntryView()
                .tabItem {
                    Label("记一笔", systemImage: "plus.circle.fill")
                }

            GrowthChartView()
                .tabItem {
                    Label("成长曲线", systemImage: "chart.xyaxis.line")
                }

            AppHistoryView()
                .tabItem {
                    Label("历史记录", systemImage: "clock.fill")
                }
        }
        .environmentObject(store)
    }
}