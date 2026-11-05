import SwiftUI
import Foundation

struct AppRootView: View {
    @StateObject private var store = AppQuoteStore()
    @State private var selectedTab = AppRootView.initialTab()

    private static let ink = Color(red: 0.16, green: 0.29, blue: 0.24)

    var body: some View {
        TabView(selection: $selectedTab) {
            AppCaptureView()
                .tabItem {
                    Label("记一句", systemImage: "square.and.pencil")
                }
                .tag(0)

            AppBookShelfView()
                .tabItem {
                    Label("书库", systemImage: "books.vertical")
                }
                .tag(1)

            AppSearchView()
                .tabItem {
                    Label("搜索", systemImage: "magnifyingglass")
                }
                .tag(2)

            AppTimelineView()
                .tabItem {
                    Label("时间线", systemImage: "calendar")
                }
                .tag(3)
        }
        .tint(AppRootView.ink)
        .environmentObject(store)
    }

    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-startTab"),
           index + 1 < args.count,
           let tab = Int(args[index + 1]) {
            return tab
        }
        return 0
    }
}