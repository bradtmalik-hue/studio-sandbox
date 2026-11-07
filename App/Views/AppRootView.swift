import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selection: Int = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                AppPage1View()
                    .navigationTitle("宠物档案")
            }
            .tabItem {
                Label("宠物档案", systemImage: "pawprint.fill")
            }
            .tag(0)

            NavigationStack {
                AppPage2View()
                    .navigationTitle("疫苗记录")
            }
            .tabItem {
                Label("疫苗记录", systemImage: "syringe.fill")
            }
            .tag(1)

            NavigationStack {
                AppPage3View()
                    .navigationTitle("提醒")
            }
            .tabItem {
                Label("提醒", systemImage: "bell.badge.fill")
            }
            .tag(2)
        }
    }

    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-startTab"), index + 1 < args.count, let value = Int(args[index + 1]) {
            return min(max(value, 0), 2)
        }
        return 0
    }
}