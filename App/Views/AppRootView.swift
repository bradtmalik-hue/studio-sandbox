import SwiftUI
import Foundation

struct AppRootView: View {
    @StateObject private var store = AppStore()
    @State private var selectedTab: Int

    init() {
        _selectedTab = State(initialValue: Self.initialTab())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            AppCheckInView()
                .tabItem {
                    Label("打卡", systemImage: "checkmark.circle.fill")
                }
                .tag(0)

            AppRecordsView()
                .tabItem {
                    Label("记录", systemImage: "list.bullet.rectangle.fill")
                }
                .tag(1)

            AppStatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.xaxis")
                }
                .tag(2)
        }
        .environmentObject(store)
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let value = Int(arguments[index + 1]) {
            return value
        }
        return 0
    }
}