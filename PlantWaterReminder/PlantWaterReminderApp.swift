import SwiftUI

@main
struct PlantWaterReminderApp: App {
    @StateObject private var _env: PlantWaterReminderStore = PlantWaterReminderStore()

    var body: some Scene {
        WindowGroup {
            PlantWaterReminderRootView()
                .environmentObject(_env)
                .tint(PlantWaterReminderTheme.accent)
        }
    }
}
