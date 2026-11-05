import SwiftUI

@main
struct AppApp: App {
    @StateObject private var _env: AppAlbumStore = AppAlbumStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(_env)
                .tint(AppTheme.accent)
        }
    }
}
