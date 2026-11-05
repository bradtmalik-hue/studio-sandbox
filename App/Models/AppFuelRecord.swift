import Foundation

struct AppFuelRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var odometer: Double
    var cost: Double
    var liters: Double

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        odometer: Double = 0,
        cost: Double = 0,
        liters: Double = 0
    ) {
        self.id = id
        self.date = date
        self.odometer = odometer
        self.cost = cost
        self.liters = liters
    }

    var pricePerLiter: Double {
        guard liters > 0 else { return 0 }
        return cost / liters
    }

    func intervalDistance(from previous: AppFuelRecord?) -> Double? {
        guard let previous else { return nil }
        let distance = odometer - previous.odometer
        guard distance > 0 else { return nil }
        return distance
    }
}