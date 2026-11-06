import SwiftUI

struct AppRootView: View {
    @StateObject private var store = AppStore()
    @State private var selectedLocation: String? = nil
    @State private var selectedTab = AppRootView.initialTab()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                AppSummaryView()
            }
            .tabItem {
                Label("概览", systemImage: "chart.pie.fill")
            }
            .tag(0)
            
            NavigationStack {
                AppMedicineListView(allLocations: $selectedLocation)
            }
            .tabItem {
                Label("药品", systemImage: "pills.fill")
            }
            .tag(1)
            
            NavigationStack {
                AppLocationView(locations: "")
            }
            .tabItem {
                Label("位置", systemImage: "cabinet.fill")
            }
            .tag(2)
        }
        .environmentObject(store)
    }
    
    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-startTab"), index + 1 < args.count, let value = Int(args[index + 1]) {
            return min(max(value, 0), 2)
        }
        return 0
    }
}

#Preview {
    AppRootView()
}