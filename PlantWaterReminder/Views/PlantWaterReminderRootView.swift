import SwiftUI
import Foundation

struct PlantWaterReminderRootView: View {
    @State private var selectedTab = PlantWaterReminderRootView.initialTab()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                PlantWaterReminderListView()
            }
            .tabItem {
                Label("Plants", systemImage: "leaf.fill")
            }
            .tag(0)
            
            NavigationStack {
                PlantWaterReminderEditView()
            }
            .tabItem {
                Label("Add Plant", systemImage: "plus.circle.fill")
            }
            .tag(1)
        }
    }
    
    private static func initialTab() -> Int {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-startTab"), i + 1 < a.count, let v = Int(a[i + 1]) {
            return v
        }
        return 0
    }
}