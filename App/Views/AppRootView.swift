import SwiftUI

struct AppRootView: App {
    @State private var store = AppMealStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}