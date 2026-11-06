import Foundation
import Combine

struct AppMealRecord: Codable, Identifiable {
    let id: UUID
    var date: Date
    var amount: Double // 单位：克
    var note: String

    init(id: UUID = UUID(), date: Date = Date(), amount: Double = 0, note: String = "") {
        self.id = id
        self.date = date
        self.amount = amount
        self.note = note
    }
}

final class DemoSeed: ObservableObject {
    static func apply() {
    }
}