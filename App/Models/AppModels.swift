import Foundation

struct AppMeal: Identifiable {
    let id: UUID
    var date: Date
    var foodName: String
    var amount: Double
    var calories: Double
    var mealType: AppMealType
    var note: String
}

enum AppMealType {
    case breakfast, lunch, dinner, snack, id
}

struct AppSettings {
    var petName: String
    var dailyMealTarget: Double
}

struct AppPayload {
    var meals: [AppMeal]
    var settings: AppSettings
}

struct DemoSeed {
    var store: AppPayload
    var calendar: Calendar
    var day: Date
}
