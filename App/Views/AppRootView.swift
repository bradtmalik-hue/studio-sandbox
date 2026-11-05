import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppMedicineStore()
    @State private var selectedTab: Int

    init() {
        _selectedTab = State(initialValue: Self.initialTab())
    }

    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-startTab"), i + 1 < args.count, let v = Int(args[i + 1]) {
            return min(max(v, 0), 2)
        }
        return 0
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                AppHomeView()
            }
            .tabItem {
                Label("首页", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                AppExpiryView()
            }
            .tabItem {
                Label("有效期", systemImage: "calendar.badge.clock")
            }
            .tag(1)

            NavigationStack {
                AppStorageView()
            }
            .tabItem {
                Label("存放位置", systemImage: "location.fill")
            }
            .tag(2)
        }
        .environmentObject(store)
    }
}