import SwiftUI

struct AppRootView: View {
    @State private var selectedTab: Int = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                AppPage1View()
            }
            .tabItem {
                Label("今天", systemImage: "drop.fill")
            }
            .tag(0)

            NavigationStack {
                AppPage2View()
            }
            .tabItem {
                Label("历史", systemImage: "calendar")
            }
            .tag(1)

            NavigationStack {
                AppPage3View()
            }
            .tabItem {
                Label("统计", systemImage: "chart.bar.fill")
            }
            .tag(2)
        }
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

#Preview {
    AppRootView()
}