import Foundation

struct BrewLogWeeklyTrendPoint: Identifiable {
    let id: Date
    let date: Date
    let averageRatio: Double
    let brewCount: Int

    init(date: Date, averageRatio: Double, brewCount: Int) {
        self.id = date
        self.date = date
        self.averageRatio = averageRatio
        self.brewCount = brewCount
    }
}

enum BrewLogFormatter {
    static func temperature(_ value: Double) -> String {
        "\(Self.decimalString(value))°C"
    }

    static func duration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    static func ratio(_ value: Double) -> String {
        "1:\(Self.decimalString(value))"
    }

    static func weeklyTrend(from brews: [BrewLogBrew], now: Date = Date(), calendar: Calendar = .current) -> [BrewLogWeeklyTrendPoint] {
        let startOfToday = calendar.startOfDay(for: now)
        let days = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: startOfToday)
        }.sorted()

        return days.map { dayStart in
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let dayBrews = brews.filter { brew in
                brew.date >= dayStart && brew.date < dayEnd
            }
            let average = dayBrews.isEmpty ? 0 : dayBrews.map(\.ratio).reduce(0, +) / Double(dayBrews.count)
            return BrewLogWeeklyTrendPoint(
                date: dayStart,
                averageRatio: average,
                brewCount: dayBrews.count
            )
        }
    }

    private static func decimalString(_ value: Double) -> String {
        if value.rounded() == value {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}