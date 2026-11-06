import SwiftUI

@main
struct AppApp: App {
    @StateObject private var _env: AppMedicineStore = AppMedicineStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(_env)
                .tint(AppTheme.accent)
        }
    }
}
