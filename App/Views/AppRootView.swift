import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selection: Int = AppRootView.initialTab()

    var body: some View {
        TabView(selection: $selection) {
            QuoteListView()
                .tabItem {
                    Label("摘录", systemImage: "quote.bubble")
                }
                .tag(0)

            AppStatsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar")
                }
                .tag(1)

            AppAboutView()
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
                .tag(2)
        }
    }

    private static func initialTab() -> Int {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-startTab"),
           index + 1 < arguments.count,
           let value = Int(arguments[index + 1]) {
            return value
        }
        return 0
    }
}

private struct AppStatsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "text.book.closed")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("书页摘")
                    .font(.largeTitle.bold())
                Text("已摘录 \(store.quotes.count) 条句子")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("随手记下读到的好句子")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            }
            .navigationTitle("统计")
        }
    }
}

private struct AppAboutView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "book.closed")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("书页摘")
                    .font(.largeTitle.bold())
                Text("版本 1.0")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text("随手记下读到的好句子，沉淀你的阅读记忆。")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("关于")
        }
    }
}