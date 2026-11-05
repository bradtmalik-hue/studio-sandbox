import Foundation

struct AppFilmRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var rating: Double
    var watchDate: Date
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        rating: Double = 0,
        watchDate: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.rating = min(max(rating, 0), 5)
        self.watchDate = watchDate
        self.createdAt = createdAt
    }
}