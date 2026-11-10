import SwiftUI
import Foundation

struct AppRootView: View {
    @StateObject private var store = AppDataStore()
    @State private var selection: Int

    init() {
        _selection = State(initialValue: AppRootView.initialTab())
    }

    var body: some View {
        TabView(selection: $selection) {
            AppPage1View()
                .tabItem { Label("Record", systemImage: "wrench.and.screwdriver") }
                .tag(0)
            AppPage2View(result: "", matchesType: false)
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(1)
            AppPage3View()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
                .tag(2)
            AppPage4View()
                .tabItem { Label("Reminders", systemImage: "bell.badge") }
                .tag(3)
        }
        .environmentObject(store)
    }

    private static func initialTab() -> Int {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"), index + 1 < arguments.count, let value = Int(arguments[index + 1]) {
            return value
        }
        #endif
        return 0
    }
}