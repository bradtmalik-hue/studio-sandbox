import Foundation
import Combine

struct AppBook: Identifiable, Codable {
    let id: UUID
    var title: String
    var author: String
    var category: String
    var pages: Int
    var rating: Double
    var isRead: Bool
    var isFinished: Bool
    var readDate: Date?
    var notes: String

    init(
        id: UUID = UUID(),
        title: String = "",
        author: String = "",
        category: String = "",
        pages: Int = 0,
        rating: Double = 0,
        isRead: Bool = false,
        isFinished: Bool = false,
        readDate: Date? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.category = category
        self.pages = pages
        self.rating = rating
        self.isRead = isRead
        self.isFinished = isFinished
        self.readDate = readDate
        self.notes = notes
    }
}

struct AppExcerpt: Identifiable, Codable {
    let originalID: UUID
    var text: String
    var pageText: String
    var note: String
    var selectedBookID: UUID?
    var createdAt: Date

    var id: UUID { originalID }

    init(
        originalID: UUID = UUID(),
        text: String = "",
        pageText: String = "",
        note: String = "",
        selectedBookID: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.originalID = originalID
        self.text = text
        self.pageText = pageText
        self.note = note
        self.selectedBookID = selectedBookID
        self.createdAt = createdAt
    }
}

class AppStore: ObservableObject {
    @Published var books: [AppBook]
    @Published var excerpts: [AppExcerpt]

    init(books: [AppBook] = [], excerpts: [AppExcerpt] = []) {
        self.books = books
        self.excerpts = excerpts
    }

    func addBook(_ book: AppBook) {
        books.append(book)
    }

    func updateBook(_ book: AppBook) {
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books[index] = book
        }
    }

    func deleteBook(_ book: AppBook) {
        books.removeAll { $0.id == book.id }
    }

    func addExcerpt(_ excerpt: AppExcerpt) {
        excerpts.append(excerpt)
    }

    func updateExcerpt(_ excerpt: AppExcerpt) {
        if let index = excerpts.firstIndex(where: { $0.id == excerpt.id }) {
            excerpts[index] = excerpt
        }
    }

    func deleteExcerpt(_ excerpt: AppExcerpt) {
        excerpts.removeAll { $0.id == excerpt.id }
    }
}