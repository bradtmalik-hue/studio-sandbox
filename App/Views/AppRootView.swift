import SwiftUI
import Foundation

struct AppRootView: View {
    @EnvironmentObject private var store: AppMedicineStore
    @State private var selectedTab: Int

    init() {
        _selectedTab = State(initialValue: Self.initialTab())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                AppMedicineDashboardView()
            }
            .tabItem {
                Label("概览", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                AppMedicineListView()
            }
            .tabItem {
                Label("药品", systemImage: "pills.fill")
            }
            .tag(1)

            NavigationStack {
                AppExpiringSoonView()
            }
            .tabItem {
                Label("临期", systemImage: "clock.fill")
            }
            .tag(2)

            NavigationStack {
                AppStorageLocationView()
            }
            .tabItem {
                Label("位置", systemImage: "location.fill")
            }
            .tag(3)
        }
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let value = Int(arguments[index + 1]) {
            return min(max(value, 0), 3)
        }
        return 0
    }
}