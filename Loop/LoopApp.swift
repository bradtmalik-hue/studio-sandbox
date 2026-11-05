import SwiftUI

@main
struct LoopApp: App {
    @StateObject private var _env: LoopStore = LoopStore()

    var body: some Scene {
        WindowGroup {
            LoopRootView()
                .task { DemoSeed.apply() }
                .environmentObject(_env)
                .tint(LoopTheme.accent)
        }
    }
}
