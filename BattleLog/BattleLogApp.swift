import SwiftUI

@main
struct BattleLogApp: App {
    @StateObject private var _env: BattleLogStore = BattleLogStore()

    var body: some Scene {
        WindowGroup {
            BattleLogRootView()
                .task { DemoSeed.apply() }
                .environmentObject(_env)
                .tint(BattleLogTheme.accent)
        }
    }
}
