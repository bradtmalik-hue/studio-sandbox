import SwiftUI

struct AppRootView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedTab: Int = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            AppMedicineListView()
                .tabItem {
                    Label("药箱", systemImage: "pills.fill")
                }
                .tag(0)

            AppAddMedicineView()
                .tabItem {
                    Label("添加", systemImage: "plus.circle.fill")
                }
                .tag(1)

            AppReminderSettingsView()
                .tabItem {
                    Label("提醒", systemImage: "bell.badge.fill")
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
        .environmentObject(AppStore())
}