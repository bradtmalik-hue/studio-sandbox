import SwiftUI

@main
struct PlantCareApp: App {
    @StateObject private var _env: PlantCareStore = PlantCareStore()

    var body: some Scene {
        WindowGroup {
            PlantCareRootView()
                .environmentObject(_env)
                .tint(PlantCareTheme.accent)
        }
    }
}
