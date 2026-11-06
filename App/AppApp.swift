import SwiftUI

@main
struct AppApp: App {

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .task { DemoSeed.apply() }
                .tint(AppTheme.accent)
        }
    }
}
