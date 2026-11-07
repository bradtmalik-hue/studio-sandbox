import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppStore()
    @State private var selectedTab = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            AppPage1View()
                .tabItem {
                    Label("今天", systemImage: "drop.fill")
                }
                .tag(0)

            AppPage2View()
                .tabItem {
                    Label("历史", systemImage: "calendar")
                }
                .tag(1)

            AppPage3View(recordCount: 0)
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .environmentObject(store)
        .tint(.primary)
    }

    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-startTab"),
           index + 1 < args.count,
           let value = Int(args[index + 1]) {
            return min(max(value, 0), 2)
        }
        return 0
    }
}