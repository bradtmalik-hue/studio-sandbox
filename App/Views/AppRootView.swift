import SwiftUI

struct AppRootView: View {
    @StateObject private var store: AppStore
    @State private var selectedTab: Int

    init() {
        _store = StateObject(wrappedValue: AppStore())
        _selectedTab = State(initialValue: Self.initialTab())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            AppPage1View()
                .tabItem {
                    Label("药品列表", systemImage: "pills.fill")
                }
                .tag(0)

            AppPage2View()
                .tabItem {
                    Label("添加一盒", systemImage: "plus.circle.fill")
                }
                .tag(1)

            AppPage3View()
                .tabItem {
                    Label("临期提醒", systemImage: "clock.badge.exclamationmark.fill")
                }
                .tag(2)
        }
        .environmentObject(store)
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let tab = Int(arguments[index + 1]) {
            return tab
        }
        return 0
    }
}