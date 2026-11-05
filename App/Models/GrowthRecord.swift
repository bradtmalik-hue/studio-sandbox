import Foundation

struct AppGrowthRecord: Codable, Identifiable, Equatable {
    var id: UUID
    var date: Date
    var heightCm: Double
    var weightKg: Double

    init(
        id: UUID = UUID(),
        date: Date,
        heightCm: Double,
        weightKg: Double
    ) {
        self.id = id
        self.date = date
        self.heightCm = heightCm
        self.weightKg = weightKg
    }

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case heightCm
        case weightKg
    }
}