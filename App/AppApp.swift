import SwiftUI

@main
struct AppApp: App {

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .tint(AppTheme.accent)
        }
    }
}
