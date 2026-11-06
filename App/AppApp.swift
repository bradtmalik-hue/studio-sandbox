import SwiftUI

@main
struct AppApp: App {
    @StateObject private var _env: AppStore = AppStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .task { DemoSeed.apply() }
                .environmentObject(_env)
                .tint(AppTheme.accent)
        }
    }
}
