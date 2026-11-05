import SwiftUI
import Foundation

struct LoopRootView: View {
    @StateObject private var store: LoopStore
    @State private var selectedTab: Int

    init() {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("loop-store.json")
        _store = StateObject(wrappedValue: LoopStore(moments: [], conversations: [], fileURL: fileURL))
        _selectedTab = State(initialValue: LoopRootView.initialTab())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            LoopMomentsView()
                .tabItem {
                    Label("Moments", systemImage: "square.grid.2x2")
                }
                .tag(0)

            LoopConversationsView()
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(1)

            LoopComposeView()
                .tabItem {
                    Label("New Moment", systemImage: "plus.circle.fill")
                }
                .tag(2)
        }
        .environmentObject(store)
        .tint(.primary)
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let tab = Int(arguments[index + 1]) {
            return min(max(tab, 0), 2)
        }
        return 0
    }
}

#Preview {
    LoopRootView()
}