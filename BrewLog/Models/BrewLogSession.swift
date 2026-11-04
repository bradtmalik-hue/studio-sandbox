import Foundation

struct BrewLogSession: Identifiable, Codable {
    let id: UUID
    var bean: BrewLogBean
    var ratio: Double
    var temp: Double
    var seconds: Int
    var date: Date

    init(
        id: UUID = UUID(),
        bean: BrewLogBean,
        ratio: Double,
        temp: Double,
        seconds: Int,
        date: Date = Date()
    ) {
        self.id = id
        self.bean = bean
        self.ratio = ratio
        self.temp = temp
        self.seconds = seconds
        self.date = date
    }
}