import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppStore()
    @State private var selectedTab: Int

    init() {
        _selectedTab = State(initialValue: Self.initialTab())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            AppPage1View(store: store)
                .tabItem {
                    Label("今天", systemImage: "figure.run.circle.fill")
                }
                .tag(0)

            AppPage2View(totalMinutes: store)
                .tabItem {
                    Label("历史", systemImage: "calendar.circle.fill")
                }
                .tag(1)

            AppPage3View()
                .tabItem {
                    Label("设置", systemImage: "gearshape.circle.fill")
                }
                .tag(2)
        }
        .environmentObject(store)
    }

    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-startTab"),
           index + 1 < args.count,
           let value = Int(args[index + 1]) {
            return value
        }
        return 0
    }
}