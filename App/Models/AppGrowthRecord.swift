import Foundation

struct AppGrowthRecord: Codable, Identifiable, Hashable {
    let id: UUID
    var date: Date
    var height: Double
    var weight: Double

    init(id: UUID = UUID(), date: Date = Date(), height: Double, weight: Double) {
        self.id = id
        self.date = date
        self.height = height
        self.weight = weight
    }
}