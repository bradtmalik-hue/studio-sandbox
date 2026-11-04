import Foundation

struct AppBrewRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var beanID: UUID
    var date: Date
    var dose: Double
    var waterAmount: Double
    var waterTemperature: Double
    var totalDuration: TimeInterval
    var isBest: Bool

    init(
        id: UUID = UUID(),
        beanID: UUID,
        date: Date = Date(),
        dose: Double,
        waterAmount: Double,
        waterTemperature: Double,
        totalDuration: TimeInterval,
        isBest: Bool = false
    ) {
        self.id = id
        self.beanID = beanID
        self.date = date
        self.dose = dose
        self.waterAmount = waterAmount
        self.waterTemperature = waterTemperature
        self.totalDuration = totalDuration
        self.isBest = isBest
    }
}