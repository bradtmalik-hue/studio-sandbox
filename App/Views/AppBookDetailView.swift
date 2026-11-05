import SwiftUI

struct AppBookDetailView: View {
    let bookTitle: String
    let quotes: [AppQuote]

    init(book: AppBookGroup) {
        self.bookTitle = "摘录"
        self.quotes = book.quotes
    }

    init(quotes: [AppQuote]) {
        self.bookTitle = "摘录"
        self.quotes = quotes
    }

    init(bookTitle: String, quotes: [AppQuote]) {
        self.bookTitle = bookTitle
        self.quotes = quotes
    }

    var body: some View {
        Group {
            if quotes.isEmpty {
                emptyState
            } else {
                quoteList
            }
        }
        .navigationTitle(bookTitle)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(white: 0.97).ignoresSafeArea())
    }

    private var sortedQuotes: [AppQuote] {
        quotes.sorted { $0.pageNumber < $1.pageNumber }
    }

    private var quoteList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(Array(sortedQuotes.enumerated()), id: \.offset) { _, quote in
                    AppQuoteCard(quote: quote)
                }
            }
            .padding()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "这本书还没有摘录",
            systemImage: "text.book.closed",
            description: Text("去“记一句”添加第一条句子吧")
        )
        .foregroundStyle(.secondary)
    }
}

private struct AppQuoteCard: View {
    let quote: AppQuote

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("第 \(quote.pageNumber) 页")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(deepGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(deepGreen.opacity(0.12)))

                Spacer()
            }

            Text(quote.quoteText)
                .font(.system(.body, design: .serif, weight: .medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    private var deepGreen: Color {
        Color(red: 0.05, green: 0.25, blue: 0.20)
    }
}