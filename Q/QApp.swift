import SwiftUI

@main
struct QApp: App {
    @StateObject private var _env: QGameStore = QGameStore()

    var body: some Scene {
        WindowGroup {
            QRootView()
                .task { DemoSeed.apply() }
                .environmentObject(_env)
                .tint(QTheme.accent)
        }
    }
}
