import SwiftUI

@main
struct AppApp: App {
    @StateObject private var _env: AppInventoryStore = AppInventoryStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(_env)
                .tint(AppTheme.accent)
        }
    }
}
