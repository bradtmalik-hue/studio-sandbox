import SwiftUI

@main
struct QApp: App {

    var body: some Scene {
        WindowGroup {
            QRootView()
                .task { DemoSeed.apply() }
                .tint(QTheme.accent)
        }
    }
}
