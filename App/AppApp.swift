import SwiftUI

@main
struct AppApp: App {
    @StateObject private var _env: AppMealStore = AppMealStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(_env)
                .tint(AppTheme.accent)
        }
    }
}
