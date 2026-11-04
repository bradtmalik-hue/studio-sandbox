import Foundation

struct BrewLogEntry: Identifiable, Codable {
    var id: UUID
    var bean: BrewBean
    var ratio: Double
    var temp: Double
    var seconds: Int
    var flavor: String
    var date: Date

    init(
        id: UUID = UUID(),
        bean: BrewBean,
        ratio: Double,
        temp: Double,
        seconds: Int,
        flavor: String,
        date: Date = Date()
    ) {
        self.id = id
        self.bean = bean
        self.ratio = ratio
        self.temp = temp
        self.seconds = seconds
        self.flavor = flavor
        self.date = date
    }
}