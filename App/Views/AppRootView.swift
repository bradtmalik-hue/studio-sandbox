import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppStore()
    @State private var selectedTab = Self.initialTab()
    private let categories = ["全部", "感冒用药", "退烧止痛", "肠胃用药", "外用药", "慢性病用药", "其他"]

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                AppMedicineListView(categories: categories)
            }
            .tabItem {
                Label("药箱", systemImage: "pills.fill")
            }
            .tag(0)

            NavigationStack {
                AppMedicineFormView(store: store, medicine: nil)
            }
            .tabItem {
                Label("添加", systemImage: "plus.circle.fill")
            }
            .tag(1)
        }
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"), index + 1 < arguments.count, let value = Int(arguments[index + 1]) {
            return value
        }
        return 0
    }
}