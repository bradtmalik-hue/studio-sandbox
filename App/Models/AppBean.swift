import Foundation

struct AppBean: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var roastDate: Date
    var initialGrams: Double
    var remainingGrams: Double

    init(
        id: UUID = UUID(),
        name: String,
        roastDate: Date,
        initialGrams: Double,
        remainingGrams: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.roastDate = roastDate
        self.initialGrams = initialGrams
        self.remainingGrams = remainingGrams ?? initialGrams
    }

    var remainingRatio: Double {
        guard initialGrams > 0 else { return 0 }
        return min(max(remainingGrams / initialGrams, 0), 1)
    }

    var daysSinceRoast: Int {
        let days = Calendar.current.dateComponents([.day], from: roastDate, to: Date()).day ?? 0
        return max(days, 0)
    }
}