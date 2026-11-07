import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppStore()
    @State private var selectedTab: Int = AppRootView.initialTab()

    init() {
        // 使用 static 方法初始化 selectedTab
    }

    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-startTab"), i + 1 < args.count, let v = Int(args[i + 1]) {
            return v
        }
        return 0
    }

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

            AppPage3View()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .environmentObject(store)
    }
}