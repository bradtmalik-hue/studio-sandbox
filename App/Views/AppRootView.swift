import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppStore()
    @State private var selectedTab: Int = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            AppPage1View()
                .tabItem {
                    Label("今天", systemImage: "sun.max.fill")
                }
                .tag(0)
            AppPage2View()
                .tabItem {
                    Label("分类", systemImage: "square.grid.2x2.fill")
                }
                .tag(1)
            AppPage3View()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .environmentObject(store)
        .tint(.primary)
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let startIndex = arguments.firstIndex(of: "-startTab"), startIndex + 1 < arguments.count, let tab = Int(arguments[startIndex + 1]) {
            return min(max(tab, 0), 2)
        }
        return 0
    }
}