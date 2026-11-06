import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppMedicineStore()
    @State private var selectedTab: Int

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        var initialTab = 0
        if let index = arguments.firstIndex(of: "-startTab"), index + 1 < arguments.count, let value = Int(arguments[index + 1]) {
            initialTab = value
        }
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            AppPage1View()
                .tabItem {
                    Label("药箱", systemImage: "pills.fill")
                }
                .tag(0)

            AppPage2View()
                .tabItem {
                    Label("添加", systemImage: "plus.circle.fill")
                }
                .tag(1)

            AppPage3View()
                .tabItem {
                    Label("临期", systemImage: "exclamationmark.triangle.fill")
                }
                .tag(2)
        }
        .environmentObject(store)
        .tint(.brown)
    }
}