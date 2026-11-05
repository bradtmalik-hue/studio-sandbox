import SwiftUI
import Foundation

struct QuoteCardView: View {
    let quote: AppQuote

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(quote.text)
                .font(.headline)
                .lineLimit(4)

            HStack {
                Text(quote.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                if quote.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }

            HStack {
                Text(quote.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Capsule())
                Spacer()
                if !quote.note.isEmpty {
                    Text(quote.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.12))
        )
    }
}

struct QuoteRowView: View {
    let quote: AppQuote

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(quote.text)
                .font(.body)
                .lineLimit(2)

            HStack {
                Text(quote.author)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if quote.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                Text(quote.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct QuoteDetailView: View {
    let quote: AppQuote

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(quote.text)
                    .font(.title2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text(quote.author)
                        .font(.headline)
                    Spacer()
                    Image(systemName: quote.isFavorite ? "star.fill" : "star")
                        .foregroundColor(quote.isFavorite ? .yellow : .gray)
                }

                Divider()

                if !quote.source.isEmpty {
                    Label {
                        Text(quote.source)
                    } icon: {
                        Image(systemName: "book")
                    }
                }

                if !quote.note.isEmpty {
                    Label {
                        Text(quote.note)
                    } icon: {
                        Image(systemName: "note.text")
                    }
                }

                Label {
                    Text("Page \(quote.page)")
                } icon: {
                    Image(systemName: "number")
                }

                Label {
                    Text(quote.category)
                } icon: {
                    Image(systemName: "tag")
                }

                Label {
                    Text(quote.dateAdded, style: .date)
                } icon: {
                    Image(systemName: "calendar")
                }

                Link(destination: quote.fileURL) {
                    Label {
                        Text("Open original file")
                    } icon: {
                        Image(systemName: "doc")
                    }
                }
            }
            .padding()
        }
        .navigationTitle(quote.author)
    }
}

struct QuoteListView: View {
    let quotes: [AppQuote]

    var body: some View {
        List {
            ForEach(quotes, id: \.id) { quote in
                NavigationLink {
                    QuoteDetailView(quote: quote)
                } label: {
                    QuoteRowView(quote: quote)
                }
            }
        }
        .navigationTitle("Quotes")
    }
}

#if DEBUG
struct AppViews_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            QuoteListView(quotes: [
                AppQuote(
                    id: UUID(),
                    text: "The unexamined life is not worth living.",
                    source: "Apology",
                    author: "Socrates",
                    page: 38,
                    note: "A classic reminder.",
                    dateAdded: Date(),
                    category: "Philosophy",
                    isFavorite: true,
                    fileURL: URL(fileURLWithPath: "/tmp/quote.txt")
                )
            ])
        }
    }
}
#endif