import SwiftUI

struct AppRootView: View {
    @State private var selectedTab: Int = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            AppPhotoLibraryView()
                .tabItem {
                    Label("图库", systemImage: "photo.on.rectangle.angled")
                }
                .tag(0)

            AppAlbumsView()
                .tabItem {
                    Label("相册", systemImage: "rectangle.stack.fill")
                }
                .tag(1)

            AppFavoritesView()
                .tabItem {
                    Label("收藏", systemImage: "heart.fill")
                }
                .tag(2)
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