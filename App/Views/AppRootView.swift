import SwiftUI
import Foundation

struct AppRootView: View {
    @StateObject private var store = AppStore()
    @State private var selectedTab = AppRootView.initialTab()
    @State private var showingAddRecord = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                AppRecordListView()
                    .navigationTitle("随手记")
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                showingAddRecord = true
                            } label: {
                                Label("记一笔", systemImage: "plus")
                            }
                        }
                    }
                    .sheet(isPresented: $showingAddRecord) {
                        NavigationStack {
                            AppAddRecordView()
                        }
                        .environmentObject(store)
                    }
            }
            .tabItem {
                Label("记录", systemImage: "list.bullet.rectangle")
            }
            .tag(0)

            NavigationStack {
                AppStatsView()
                    .navigationTitle("统计")
            }
            .tabItem {
                Label("统计", systemImage: "chart.bar.fill")
            }
            .tag(1)
        }
        .environmentObject(store)
        .tint(.primary)
    }

    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-startTab"), index + 1 < args.count, let value = Int(args[index + 1]) {
            return min(max(value, 0), 1)
        }
        return 0
    }
}