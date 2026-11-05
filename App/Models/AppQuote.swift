import Foundation

struct AppQuote: Identifiable, Codable, Hashable {
    let id: UUID
    var bookTitle: String
    var pageNumber: String
    var quoteText: String
    var note: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        bookTitle: String,
        pageNumber: String,
        quoteText: String,
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.bookTitle = bookTitle
        self.pageNumber = pageNumber
        self.quoteText = quoteText
        self.note = note
        self.createdAt = createdAt
    }
}