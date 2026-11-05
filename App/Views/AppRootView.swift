import SwiftUI
import Foundation

struct AppRootView: View {
    @StateObject private var store: AppStore
    @State private var selectedTab: Int

    init() {
        _store = StateObject(wrappedValue: AppStore())
        _selectedTab = State(initialValue: Self.initialTab())
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let value = Int(arguments[index + 1]) {
            return value
        }
        return 0
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            AppCaptureView()
                .tabItem {
                    Label("记一句", systemImage: "quote.bubble")
                }
                .tag(0)

            AppBookshelfView()
                .tabItem {
                    Label("书架", systemImage: "books.vertical")
                }
                .tag(1)

            AppSearchView()
                .tabItem {
                    Label("搜索", systemImage: "magnifyingglass")
                }
                .tag(2)
        }
        .environmentObject(store)
    }
}