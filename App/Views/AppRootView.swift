import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            AppHomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(0)

            AppRecordListView()
                .tabItem {
                    Label("记录", systemImage: "list.bullet.rectangle.fill")
                }
                .tag(1)

            AppGrowthChartView()
                .tabItem {
                    Label("曲线", systemImage: "chart.xyaxis.line")
                }
                .tag(2)

            AppChildListView()
                .tabItem {
                    Label("孩子", systemImage: "person.2.fill")
                }
                .tag(3)

            AppSettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(.green)
    }
}