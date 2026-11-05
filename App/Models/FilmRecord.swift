import Foundation

struct AppFilmRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var starRating: Int
    var watchDate: Date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        starRating: Int,
        watchDate: Date,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.starRating = starRating
        self.watchDate = watchDate
        self.createdAt = createdAt
    }
}