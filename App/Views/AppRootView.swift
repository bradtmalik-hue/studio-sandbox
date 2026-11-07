import SwiftUI
import Foundation

struct AppRootView: View {
    @State private var selectedTab: Int

    init() {
        let args = ProcessInfo.processInfo.arguments
        var initial = 0
        if let index = args.firstIndex(of: "-startTab"), index + 1 < args.count, let value = Int(args[index + 1]) {
            initial = value
        }
        if initial < 0 { initial = 0 }
        if initial > 2 { initial = 2 }
        _selectedTab = State(initialValue: initial)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            AppPage1View()
                .tag(0)
                .tabItem {
                    Label("今天", systemImage: "sun.max.fill")
                }

            AppPage2View()
                .tag(1)
                .tabItem {
                    Label("历史", systemImage: "calendar")
                }

            AppPage3View()
                .tag(2)
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
        }
    }
}