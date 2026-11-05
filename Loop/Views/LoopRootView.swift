import SwiftUI
import Foundation

struct LoopRootView: View {
    @State private var selectedTab: Int = LoopRootView.initialTab()

    var body: some View {
        TabView(selection: $selectedTab) {
            LoopMomentsView()
                .tabItem {
                    Label("Moments", systemImage: "camera.fill")
                }
                .tag(0)

            LoopChatsView()
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(1)

            LoopPeopleView()
                .tabItem {
                    Label("People", systemImage: "person.2.fill")
                }
                .tag(2)
        }
        .tint(.primary)
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