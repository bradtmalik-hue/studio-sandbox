import SwiftUI

@main
struct AppApp: App {
    @StateObject private var _env: AppDataStore = AppDataStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(_env)
                .tint(AppTheme.accent)
        }
    }
}
