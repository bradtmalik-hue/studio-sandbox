import SwiftUI
import Foundation

struct AppRootView: View {
    @StateObject private var store: AppStore
    @State private var selectedTab: Int

    init() {
        DemoSeed.apply()
        _store = StateObject(wrappedValue: AppStore())

        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let value = Int(arguments[index + 1]) {
            _selectedTab = State(initialValue: value)
        } else {
            _selectedTab = State(initialValue: 0)
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                AppFilmListView()
            }
            .tabItem {
                Label("片单", systemImage: "film.stack")
            }
            .tag(0)

            NavigationStack {
                AppStatsView()
            }
            .tabItem {
                Label("统计", systemImage: "chart.bar.xaxis")
            }
            .tag(1)

            NavigationStack {
                AppAboutView()
            }
            .tabItem {
                Label("关于", systemImage: "info.circle")
            }
            .tag(2)
        }
        .tint(.primary)
        .environmentObject(store)
    }
}