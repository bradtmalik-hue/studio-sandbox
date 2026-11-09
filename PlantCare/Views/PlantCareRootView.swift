import SwiftUI

struct PlantCareRootView: View {
    @StateObject private var store = PlantCareStore()
    @State private var selectedTab: Int

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let tab = Int(arguments[index + 1]) {
            _selectedTab = State(initialValue: min(max(0, tab), 3))
        } else {
            _selectedTab = State(initialValue: 0)
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                PlantCarePage1View()
            }
            .tabItem {
                Label("Today", systemImage: "drop.circle.fill")
            }
            .tag(0)

            NavigationStack {
                PlantCarePage2View()
            }
            .tabItem {
                Label("Plants", systemImage: "leaf.circle.fill")
            }
            .tag(1)

            NavigationStack {
                PlantCarePage3View(plant: "")
            }
            .tabItem {
                Label("Detail", systemImage: "list.bullet.clipboard.fill")
            }
            .tag(2)

            NavigationStack {
                PlantCarePage4View()
            }
            .tabItem {
                Label("Add Plant", systemImage: "plus.circle.fill")
            }
            .tag(3)
        }
        .environmentObject(store)
    }
}