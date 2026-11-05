import SwiftUI

struct AppSearchView: View {
    @EnvironmentObject private var store: AppQuoteStore
    @State private var searchText: String = ""

    private var trimmedKeyword: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredQuotes: [AppQuote] {
        guard !trimmedKeyword.isEmpty else { return [] }
        return store.quotes.filter { $0.text.localizedCaseInsensitiveContains(trimmedKeyword) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if trimmedKeyword.isEmpty {
                    ContentUnavailableView(
                        "搜索摘录",
                        systemImage: "magnifyingglass",
                        description: Text("输入关键词，搜索你记下的句子。")
                    )
                } else if filteredQuotes.isEmpty {
                    ContentUnavailableView(
                        "没有找到相关句子",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("换个关键词试试看。")
                    )
                } else {
                    List(filteredQuotes) { quote in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(quote.text)
                                .font(.body)
                                .foregroundStyle(.primary)

                            HStack(spacing: 4) {
                                Image(systemName: "book.closed")
                                    .font(.caption)
                                Text(quote.bookTitle)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("搜索")
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "关键词"
        )
    }
}