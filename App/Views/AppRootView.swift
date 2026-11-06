import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppStore()
    @State private var selection: Int = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                AppTodayView()
            }
            .tabItem {
                Label("今日", systemImage: "sun.max.fill")
            }
            .tag(0)

            NavigationStack {
                AppHistoryView()
            }
            .tabItem {
                Label("历史", systemImage: "clock.arrow.circlepath")
            }
            .tag(1)

            NavigationStack {
                AppAddRecordView()
            }
            .tabItem {
                Label("添加", systemImage: "plus.circle.fill")
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