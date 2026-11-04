import SwiftUI

@main
struct BrewLogApp: App {
    var body: some Scene {
        WindowGroup {
            BrewLogRootView()
                .tint(BrewLogTheme.accent)
        }
    }
}
