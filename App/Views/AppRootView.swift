import SwiftUI
import Foundation

struct AppRootView: View {
    @StateObject private var store = AppStore()
    @State private var selectedTab = Self.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            AppPage1View()
                .tabItem {
                    Label("今天", systemImage: "sun.max")
                }
                .tag(0)

            AppPage2View()
                .tabItem {
                    Label("已完成", systemImage: "checkmark.circle")
                }
                .tag(1)

            AppPage3View()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(2)
        }
        .environmentObject(store)
    }

    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-startTab"),
           i + 1 < args.count,
           let v = Int(args[i + 1]) {
            return min(max(v, 0), 2)
        }
        return 0
    }
}