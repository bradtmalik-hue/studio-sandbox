import SwiftUI
import Foundation

struct AppRootView: View {
    @State private var selection: Int = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selection) {
            AppPage1View()
                .tabItem {
                    Label("今天", systemImage: "drop.fill")
                }
                .tag(0)
            AppPage2()
                .tabItem {
                    Label("历史", systemImage: "calendar")
                }
                .tag(1)
            AppPage3View()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let value = Int(arguments[index + 1]) {
            return min(max(value, 0), 2)
        }
        return 0
    }
}