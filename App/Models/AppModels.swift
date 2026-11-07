import Foundation
import SwiftUI

struct AppFeedRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var foodType: String
    var amount: Double
    var note: String

    init(id: UUID = UUID(), date: Date = Date(), foodType: String, amount: Double, note: String = "") {
        self.id = id
        self.date = date
        self.foodType = foodType
        self.amount = amount
        self.note = note
    }
}

struct AppSettings: Codable, Hashable {
    var petName: String
    var dailyTarget: Int

    init(petName: String = "", dailyTarget: Int = 300) {
        self.petName = petName
        self.dailyTarget = dailyTarget
    }
}

struct AppPersistedData: Codable {
    var feedingRecords: [AppFeedRecord]
    var settings: AppSettings

    init(feedingRecords: [AppFeedRecord] = [], settings: AppSettings = AppSettings(petName: "", dailyTarget: 0)) {
        self.feedingRecords = feedingRecords
        self.settings = settings
    }
}

final class AppStore: ObservableObject {
    @Published var records: [AppFeedRecord] = []
    @Published var settings: AppSettings = AppSettings(petName: "", dailyTarget: 0)
}

struct AppPage2DayGroup: Identifiable {
    let id: Date
    var records: [AppFeedRecord] = []
}

struct DemoSeed {
    var store: AppStore
    var now: Date
    var calendar: Calendar
    var base: [AppFeedRecord]

    init(store: AppStore = AppStore(), now: Date = Date(), calendar: Calendar = .current) {
        self.store = store
        self.now = now
        self.calendar = calendar
        self.base = [
            AppFeedRecord(id: UUID(), date: calendar.date(byAdding: .day, value: -1, to: now) ?? now, foodType: "干粮", amount: 30, note: "早餐"),
            AppFeedRecord(id: UUID(), date: now, foodType: "罐头", amount: 50, note: "晚餐")
        ]
    }
}
