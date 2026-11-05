import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppRunStore()
    @State private var selectedTab: Int = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            AppAddRunView()
                .tabItem {
                    Label("记一次跑", systemImage: "figure.run")
                }
                .tag(0)

            AppRunLogView()
                .tabItem {
                    Label("跑步记录", systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(1)

            AppWeeklyVolumeView()
                .tabItem {
                    Label("周跑量", systemImage: "chart.bar.xaxis")
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

#Preview {
    AppRootView()
}