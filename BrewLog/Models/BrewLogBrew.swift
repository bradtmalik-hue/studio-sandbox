import Foundation

struct BrewLogBrew: Identifiable, Codable {
    var id: UUID
    var bean: BrewLogBean
    var ratio: Double
    var temp: Double
    var seconds: Int
    var flavor: String
    var date: Date

    init(
        id: UUID = UUID(),
        bean: BrewLogBean,
        ratio: Double = 16.0,
        temp: Double = 92.0,
        seconds: Int = 120,
        flavor: String = "",
        date: Date = .now
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