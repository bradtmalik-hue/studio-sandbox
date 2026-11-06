import SwiftUI

struct AppRootView: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    func task(into store: AppMealStore) -> some View {
        ContentView()
    }
}