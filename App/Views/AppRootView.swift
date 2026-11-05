import Foundation
import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppStore()
    @State private var selectedTab: Int = Self.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(0)

            RecordListView()
                .tabItem {
                    Label("记录", systemImage: "list.bullet.rectangle")
                }
                .tag(1)

            AddRecordView()
                .tabItem {
                    Label("添加", systemImage: "plus.circle.fill")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle")
                }
                .tag(3)
        }
        .environmentObject(store)
        .tint(.blue)
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let tab = Int(arguments[index + 1]) {
            return min(max(tab, 0), 3)
        }
        return 0
    }
}

#Preview {
    AppRootView()
}