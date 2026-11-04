import Foundation

struct AppBrewSuggestion {
    let ratio: Double
    let waterTemperature: Double
    let brewTime: TimeInterval

    var ratioText: String {
        String(format: "1:%.1f", ratio)
    }

    var temperatureText: String {
        String(format: "%.0f°C", waterTemperature)
    }

    var timeText: String {
        let totalSeconds = Int(brewTime)
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}

enum AppBrewCalculator {
    static func remainingCups(for bean: AppCoffeeBean) -> Double {
        guard bean.defaultCupGrams > 0 else { return 0 }
        return max(0, bean.remainingGrams / bean.defaultCupGrams)
    }

    static func brewSuggestion(for bean: AppCoffeeBean, now: Date = Date()) -> AppBrewSuggestion? {
        guard bean.remainingGrams > 0 else { return nil }
        let days = daysSinceRoast(for: bean, now: now)
        let ratio: Double
        let temperature: Double
        let time: TimeInterval

        switch days {
        case 0..<3:
            ratio = 15.0
            temperature = 88.0
            time = 120
        case 3...7:
            ratio = 16.0
            temperature = 92.0
            time = 150
        case 8...14:
            ratio = 16.5
            temperature = 91.0
            time = 165
        default:
            ratio = 15.0
            temperature = 93.0
            time = 140
        }

        return AppBrewSuggestion(ratio: ratio, waterTemperature: temperature, brewTime: time)
    }

    static func deductOneCup(from bean: AppCoffeeBean) -> AppCoffeeBean {
        deduct(grams: bean.defaultCupGrams, from: bean)
    }

    static func deduct(grams: Double, from bean: AppCoffeeBean) -> AppCoffeeBean {
        var updated = bean
        updated.remainingGrams = max(0, bean.remainingGrams - grams)
        return updated
    }

    private static func daysSinceRoast(for bean: AppCoffeeBean, now: Date) -> Int {
        let days = Calendar.current.dateComponents([.day], from: bean.roastDate, to: now).day ?? 0
        return max(0, days)
    }
}