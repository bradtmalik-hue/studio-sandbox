import SwiftUI

struct AppRootView: View {
    @State private var selectedTab: Int = AppRootView.initialTab()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("记一笔", systemImage: "plus.circle.fill") {
                AppPage1View()
            }
            .tag(0)
            
            Tab("结果", systemImage: "person.2.wave.2.fill") {
                AppPage2View(
                    balances: [],
                    dict: [:],
                    transfers: [],
                    creditors: [],
                    debtors: [],
                    result: [],
                    filtered: []
                )
            }
            .tag(1)
            
            Tab("设置", systemImage: "gearshape.fill") {
                AppPage3View()
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