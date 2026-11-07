import Foundation
import Combine

struct AppBook: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var author: String
    var currentPage: Int
    var totalPages: Int
    var startDate: Date
    var lastReadAt: Date

    init(id: UUID = UUID(), title: String, author: String, currentPage: Int, totalPages: Int, startDate: Date, lastReadAt: Date) {
        self.id = id
        self.title = title
        self.author = author
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.startDate = startDate
        self.lastReadAt = lastReadAt
    }

    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage) / Double(totalPages)
    }

    var isCompleted: Bool {
        totalPages > 0 && currentPage >= totalPages
    }

    var isReading: Bool {
        currentPage > 0 && currentPage < totalPages
    }
}

struct AppExcerpt: Identifiable, Codable, Equatable {
    let id: UUID
    var bookID: UUID?
    var text: String
    var createdAt: Date

    init(id: UUID = UUID(), bookID: UUID? = nil, text: String, createdAt: Date = Date()) {
        self.id = id
        self.bookID = bookID
        self.text = text
        self.createdAt = createdAt
    }

    var characterCount: Int {
        text.count
    }
}

final class AppStore: ObservableObject {
    @Published var books: [AppBook] = []
    @Published var excerpts: [AppExcerpt] = []

    init() {}

    func addBook(_ book: AppBook) {
        books.append(book)
    }

    func updateBook(_ book: AppBook) {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
        books[index] = book
    }

    func deleteBook(_ book: AppBook) {
        books.removeAll { $0.id == book.id }
        excerpts.removeAll { $0.bookID == book.id }
    }

    func addExcerpt(_ excerpt: AppExcerpt) {
        excerpts.append(excerpt)
    }

    func updateExcerpt(_ excerpt: AppExcerpt) {
        guard let index = excerpts.firstIndex(where: { $0.id == excerpt.id }) else { return }
        excerpts[index] = excerpt
    }

    func deleteExcerpt(_ excerpt: AppExcerpt) {
        excerpts.removeAll { $0.id == excerpt.id }
    }
}