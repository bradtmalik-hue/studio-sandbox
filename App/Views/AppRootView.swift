import SwiftUI

struct AppRootView: View {
    @State private var selectedTab: Int = AppRootView.initialTab()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AppPage1View()
                .tabItem {
                    Label("记一笔", systemImage: "plus.circle.fill")
                }
                .tag(0)
            
            AppPage2View(
                balances: [],
                dict: [:],
                transfers: [],
                creditors: [],
                debtors: [],
                result: [],
                filtered: []
            )
            .tabItem {
                Label("结果", systemImage: "person.2.wave.2.fill")
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