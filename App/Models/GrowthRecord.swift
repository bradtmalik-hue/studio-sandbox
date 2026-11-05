import Foundation

struct AppGrowthRecord: Codable, Identifiable, Equatable, Hashable, Sendable {
    var id: UUID
    var date: Date
    var heightCm: Double
    var weightKg: Double

    init(id: UUID = UUID(), date: Date, heightCm: Double, weightKg: Double) {
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.date = try container.decode(Date.self, forKey: .date)
        self.heightCm = try container.decode(Double.self, forKey: .heightCm)
        self.weightKg = try container.decode(Double.self, forKey: .weightKg)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(heightCm, forKey: .heightCm)
        try container.encode(weightKg, forKey: .weightKg)
    }
}