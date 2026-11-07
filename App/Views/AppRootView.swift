import SwiftUI
import Foundation

struct AppRootView: View {
    @StateObject private var store = AppStore()
    @State private var selectedTab = Self.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            AppPage1View()
                .tabItem {
                    Label("录摘录", systemImage: "square.and.pencil")
                }
                .tag(0)

            AppPage2View()
                .tabItem {
                    Label("摘录", systemImage: "books.vertical")
                }
                .tag(1)

            AppPage3View()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
                .tag(2)
        }
        .environmentObject(store)
    }

    private static func initialTab() -> Int {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-startTab"), i + 1 < a.count, let v = Int(a[i + 1]) {
            return v
        }
        return 0
    }
}

#Preview {
    AppRootView()
}