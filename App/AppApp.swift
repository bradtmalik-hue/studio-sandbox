import SwiftUI

@main
struct AppApp: App {
    @StateObject private var _env: AppMedicineStore = AppMedicineStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .task { DemoSeed.apply() }
                .environmentObject(_env)
                .tint(AppTheme.accent)
        }
    }
}
