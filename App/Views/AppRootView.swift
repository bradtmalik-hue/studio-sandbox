import Foundation
import SwiftUI

struct AppRootView: View {
    @State private var selectedTab: Int = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            AppPage1View()
                .tabItem {
                    Label("在读", systemImage: "book.fill")
                }
                .tag(0)

            AppPage2View()
                .tabItem {
                    Label("摘录", systemImage: "quote.bubble")
                }
                .tag(1)

            AppPage3View()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
                .tag(2)
        }
        .tint(.brown)
    }

    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-startTab"),
           index + 1 < args.count,
           let value = Int(args[index + 1]) {
            return min(max(value, 0), 2)
        }
        return 0
    }
}

#Preview {
    AppRootView()
        .environmentObject(AppStore())
}