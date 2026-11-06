import SwiftUI
import Foundation

struct AppRootView: View {
    @StateObject private var store = AppMedicineStore()
    @State private var selectedTab = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            AppPage1View(medicine: store)
                .tabItem {
                    Label("药箱", systemImage: "pills")
                }
                .tag(0)

            AppPage2()
                .tabItem {
                    Label("添加", systemImage: "plus.circle")
                }
                .tag(1)

            AppPage3View(store: store)
                .tabItem {
                    Label("临期", systemImage: "clock")
                }
                .tag(2)
        }
        .environmentObject(store)
        .tint(.gray)
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let startIndex = arguments.firstIndex(of: "-startTab"),
           startIndex + 1 < arguments.count,
           let value = Int(arguments[startIndex + 1]) {
            return min(max(value, 0), 2)
        }
        return 0
    }
}