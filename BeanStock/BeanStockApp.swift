import SwiftUI

@main
struct BeanStockApp: App {
    @StateObject private var _env: BeanStockStore = BeanStockStore()

    var body: some Scene {
        WindowGroup {
            BeanStockRootView()
                .environmentObject(_env)
                .tint(BeanStockTheme.accent)
        }
    }
}
