import SwiftUI
import Foundation

typealias AppHomeView = AppViews
typealias AppRecordListView = AppViews

struct AppRootView: View {
    @StateObject private var store = AppStore()
    @State private var selection = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selection) {
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

            AppGrowthChartView(data: store.records.map { $0.heightCm }, lineColor: .green)
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
        .environmentObject(store)
        .tint(.green)
    }

    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-startTab"),
           index + 1 < args.count,
           let value = Int(args[index + 1]) {
            return min(max(value, 0), 4)
        }
        return 0
    }
}