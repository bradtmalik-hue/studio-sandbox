import SwiftUI

struct LoopRootView: View {
    @StateObject private var store = LoopStore()
    @State private var selectedTab: Int = LoopRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                LoopMomentsView()
            }
            .tabItem {
                Label("Moments", systemImage: "photo.stack")
            }
            .tag(0)

            NavigationStack {
                LoopLoopView()
            }
            .tabItem {
                Label("Loop", systemImage: "arrow.triangle.2.circlepath")
            }
            .tag(1)

            NavigationStack {
                LoopProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(2)
        }
        .environmentObject(store)
    }

    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-startTab"),
           index + 1 < args.count,
           let value = Int(args[index + 1]),
           (0...2).contains(value) {
            return value
        }
        return 0
    }
}