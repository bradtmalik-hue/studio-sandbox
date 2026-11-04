import Foundation

struct AppCoffeeBean: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var roastDate: Date
    var remainingGrams: Double
    var defaultCupGrams: Double

    init(
        id: UUID = UUID(),
        name: String,
        roastDate: Date,
        remainingGrams: Double,
        defaultCupGrams: Double
    ) {
        self.id = id
        self.name = name
        self.roastDate = roastDate
        self.remainingGrams = remainingGrams
        self.defaultCupGrams = defaultCupGrams
    }
}