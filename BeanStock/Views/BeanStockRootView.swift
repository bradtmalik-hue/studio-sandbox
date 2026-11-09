import SwiftUI

struct BeanStockRootView: View {
    @State private var selectedTab: Int

    init() {
        _selectedTab = State(initialValue: Self.initialTab())
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let value = Int(arguments[index + 1]) {
            return min(max(value, 0), 3)
        }
        return 0
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            BeanStockPage1View()
                .tabItem {
                    Label("Bags", systemImage: "bag")
                }
                .tag(0)

            BeanStockPage2View()
                .tabItem {
                    Label("Details", systemImage: "doc.text.magnifyingglass")
                }
                .tag(1)

            BeanStockPage3View()
                .tabItem {
                    Label("Log", systemImage: "plus.circle")
                }
                .tag(2)

            BeanStockPage4View(days: 0, start: Date(), grouped: "", dict: "")
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.xaxis")
                }
                .tag(3)
        }
    }
}