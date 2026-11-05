import Foundation

struct AppGrowthRecord: Codable, Identifiable, Equatable, Hashable, Sendable {
    var id: UUID = UUID()
    var date: Date
    var heightCm: Double
    var weightKg: Double
}