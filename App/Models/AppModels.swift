import Foundation
import Combine

struct AppQuote: Identifiable, Codable, Equatable {
    var id: UUID
    var text: String
    var bookTitle: String
    var author: String
    var page: Int
    var note: String
    var createdAt: Date
    var tags: [String]

    init(
        id: UUID = UUID(),
        text: String,
        bookTitle: String,
        author: String = "",
        page: Int = 0,
        note: String = "",
        createdAt: Date = Date(),
        tags: [String] = []
    ) {
        self.id = id
        self.text = text
        self.bookTitle = bookTitle
        self.author = author
        self.page = page
        self.note = note
        self.createdAt = createdAt
        self.tags = tags
    }
}

struct AppBook: Identifiable, Equatable {
    let id: String
    var title: String
    var author: String
    var quoteCount: Int

    init(title: String, author: String, quoteCount: Int) {
        self.title = title
        self.author = author
        self.id = title + "|" + author
        self.quoteCount = quoteCount
    }
}

final class AppStore: ObservableObject {
    @Published var quotes: [AppQuote] = []

    private static let dataFileName = "app_quotes.json"

    static var dataFileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(dataFileName)
    }

    init() {
        load()
    }

    // MARK: - 数据操作

    func addQuote(_ quote: AppQuote) {
        quotes.append(quote)
        save()
    }

    func updateQuote(_ quote: AppQuote) {
        guard let index = quotes.firstIndex(where: { $0.id == quote.id }) else { return }
        quotes[index] = quote
        save()
    }

    func deleteQuote(_ quote: AppQuote) {
        quotes.removeAll { $0.id == quote.id }
        save()
    }

    func deleteQuotes(at offsets: IndexSet) {
        for offset in offsets.sorted(by: >) {
            if offset < quotes.count {
                quotes.remove(at: offset)
            }
        }
        save()
    }

    // MARK: - 书架

    var books: [AppBook] {
        let grouped = Dictionary(grouping: quotes) { $0.bookTitle }
        return grouped.map { title, quotes in
            let author = quotes.first?.author ?? ""
            return AppBook(title: title, author: author, quoteCount: quotes.count)
        }
        .sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
    }

    func quotes(forBook title: String) -> [AppQuote] {
        quotes.filter { $0.bookTitle == title }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - 搜索

    func searchQuotes(_ query: String) -> [AppQuote] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        let terms = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().split(separator: " ")
        return quotes.filter { quote in
            let haystack = "\(quote.text) \(quote.bookTitle) \(quote.author) \(quote.note) \(quote.tags.joined(separator: " "))".lowercased()
            return terms.allSatisfy { haystack.contains($0) }
        }
        .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - 本地存储

    private func save() {
        do {
            let data = try JSONEncoder().encode(quotes)
            try data.write(to: Self.dataFileURL)
        } catch {
            // 保存失败时静默处理；实际场景可暴露错误
        }
    }

    private func load() {
        let url = Self.dataFileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            quotes = try JSONDecoder().decode([AppQuote].self, from: data)
        } catch {
            quotes = []
        }
    }
}