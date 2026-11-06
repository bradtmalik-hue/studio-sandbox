import SwiftUI

@main
struct QApp: App {
    @StateObject private var _env: QStore = QStore()

    var body: some Scene {
        WindowGroup {
            QRootView()
                .task { DemoSeed.apply() }
                .environmentObject(_env)
                .tint(QTheme.accent)
        }
    }
}
