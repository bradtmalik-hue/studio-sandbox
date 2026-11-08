import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppInventoryStore()
    @State private var selectedTab = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            AppPage1View()
                .tabItem {
                    Label("库存", systemImage: "shippingbox.fill")
                }
                .tag(0)

            AppPage2View(item: "")
                .tabItem {
                    Label("新增", systemImage: "plus.circle.fill")
                }
                .tag(1)

            AppPage3View()
                .tabItem {
                    Label("统计", systemImage: "chart.pie.fill")
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
            return min(max(value, 0), 2)
        }
        return 0
    }
}