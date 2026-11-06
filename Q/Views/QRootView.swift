import SwiftUI

struct QRootView: View {
    @State private var selectedTab: Int = QRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            QHomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(0)

            QGeneralLibraryView()
                .tabItem {
                    Label("武将库", systemImage: "person.3.fill")
                }
                .tag(1)

            QBattleView()
                .tabItem {
                    Label("闯关", systemImage: "figure.run")
                }
                .tag(2)

            QBattleHistoryView()
                .tabItem {
                    Label("战史", systemImage: "clock.arrow.circlepath")
                }
                .tag(3)
        }
    }

    private static func initialTab() -> Int {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-startTab"), i + 1 < a.count, let v = Int(a[i + 1]) {
            return v
        }
        return 0
    }
}