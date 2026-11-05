import SwiftUI

struct LoopRootView: View {
    @StateObject private var store: LoopStore
    @State private var selectedTab: Int

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        var initialTab = 0
        if let index = arguments.firstIndex(of: "-startTab"), index + 1 < arguments.count, let value = Int(arguments[index + 1]) {
            initialTab = value
        }
        initialTab = min(max(initialTab, 0), 2)
        _store = StateObject(wrappedValue: LoopStore())
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                LoopTimelineView()
            }
            .tabItem {
                Label("Timeline", systemImage: "calendar.day.timeline.left")
            }
            .tag(0)

            NavigationStack {
                LoopComposeView()
            }
            .tabItem {
                Label("New Moment", systemImage: "square.and.pencil")
            }
            .tag(1)

            NavigationStack {
                LoopAboutView()
            }
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
            .tag(2)
        }
        .environmentObject(store)
        .tint(.gray)
    }
}

struct LoopAboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "repeat.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Loop")
                .font(.largeTitle.weight(.semibold))
            Text("Share your moments, keep your loop")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .padding()
        .navigationTitle("About")
    }
}