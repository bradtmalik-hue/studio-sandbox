import SwiftUI
import Foundation

struct AppRootView: View {
    @StateObject private var store = AppMedicineStore()
    @State private var selectedTab = Self.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            AppMedicineListView()
                .tabItem {
                    Label("药品", systemImage: "pills")
                }
                .tag(0)

            AppExpiryReminderView()
                .tabItem {
                    Label("临期提醒", systemImage: "exclamationmark.triangle")
                }
                .tag(1)

            AppLocationView()
                .tabItem {
                    Label("存放位置", systemImage: "location")
                }
                .tag(2)
        }
        .environmentObject(store)
    }

    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-startTab"), i + 1 < args.count, let v = Int(args[i + 1]) {
            return min(max(0, v), 2)
        }
        return 0
    }
}