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
            AppPage1View()
                .tabItem {
                    Label("正在读", systemImage: "book.fill")
                }
                .tag(0)

            AppPage2View()
                .tabItem {
                    Label("摘录", systemImage: "quote.bubble")
                }
                .tag(1)

            AppPage3View()
                .tabItem {
                    Label("目标", systemImage: "target")
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