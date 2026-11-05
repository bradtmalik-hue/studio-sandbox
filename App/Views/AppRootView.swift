import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedTab = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            AppCollectionView()
                .tabItem {
                    Label("图集", systemImage: "photo.on.rectangle.angled")
                }
                .tag(0)

            AppAddImageView()
                .tabItem {
                    Label("添加", systemImage: "plus.circle")
                }
                .tag(1)

            AppSettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
                .tag(2)
        }
        .preferredColorScheme(.light)
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let value = Int(arguments[index + 1]) {
            return value
        }
        return 0
    }
}