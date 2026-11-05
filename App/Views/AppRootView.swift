import Foundation
import SwiftUI
import Combine

struct AppRootView: View {
    @State private var store: AppModels
    @State private var selectedTab: Int

    init() {
        _store = State(initialValue: AppModels())
        _selectedTab = State(initialValue: AppRootView.initialTab())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            AppMedicationListView(medication: store)
                .tabItem {
                    Label("药箱", systemImage: "pills")
                }
                .tag(0)

            AppAddMedicationView()
                .tabItem {
                    Label("加药", systemImage: "plus.circle.fill")
                }
                .tag(1)

            AppReminderSettingsView()
                .tabItem {
                    Label("提醒", systemImage: "bell.fill")
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