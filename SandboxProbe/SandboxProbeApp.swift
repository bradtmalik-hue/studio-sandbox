import SwiftUI

@main
struct SandboxProbeApp: App {
    var body: some Scene {
        WindowGroup {
            SandboxProbeRootView()
                .tint(SandboxProbeTheme.accent)
        }
    }
}
