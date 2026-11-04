import Foundation

struct AppBrewRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var beanID: UUID
    var date: Date
    var ratio: Double
    var waterTemperature: Double
    var brewTime: TimeInterval

    init(
        id: UUID = UUID(),
        beanID: UUID,
        date: Date = Date(),
        ratio: Double = 15.0,
        waterTemperature: Double = 92.0,
        brewTime: TimeInterval = 150.0
    ) {
        self.id = id
        self.beanID = beanID
        self.date = date
        self.ratio = ratio
        self.waterTemperature = waterTemperature
        self.brewTime = brewTime
    }
}