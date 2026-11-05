import SwiftUI

struct AppRootView: View {
    @EnvironmentObject var store: AppStore

    @State private var selectedTab: Int

    init() {
        _selectedTab = State(initialValue: Self.initialTab())
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let tabValue = Int(arguments[index + 1]) {
            return tabValue
        }
        return 0
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            AppLensLibraryView()
                .tabItem {
                    Label("镜头库", systemImage: "camera")
                }
                .tag(0)

            AppAddLensView()
                .tabItem {
                    Label("添加镜头", systemImage: "plus.circle")
                }
                .tag(1)

            AppInvestmentStatsView()
                .tabItem {
                    Label("投入统计", systemImage: "chart.pie")
                }
                .tag(2)
        }
    }
}