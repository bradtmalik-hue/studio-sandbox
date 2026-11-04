import Foundation

enum BrewLogTrendBucket: String, Codable, Hashable {
    case increase
    case decrease
    case stable
    case notEnoughData
}

struct BrewLogDailyRatioStat: Identifiable, Hashable {
    let id = UUID()
    let day: Date
    let averageRatio: Double
    let trendBucket: BrewLogTrendBucket
}

struct BrewLogStatistics {
    static func dailyRatioStats(for entries: [BrewLogEntry], calendar: Calendar = .current, days: Int = 7) -> [BrewLogDailyRatioStat] {
        guard days > 0 else { return [] }
        
        let now = Date()
        guard let startOfToday = calendar.dateInterval(of: .day, for: now)?.start else { return [] }
        guard let startDay = calendar.date(byAdding: .day, value: -(days - 1), to: startOfToday) else { return [] }
        
        let filtered = entries.filter { entry in
            let dayStart = calendar.dateInterval(of: .day, for: entry.date)?.start ?? entry.date
            return dayStart >= startDay && dayStart <= startOfToday
        }
        
        let grouped = Dictionary(grouping: filtered) { entry -> Date in
            calendar.dateInterval(of: .day, for: entry.date)?.start ?? entry.date
        }
        
        let daysWithData = grouped.keys.sorted()
        guard !daysWithData.isEmpty else { return [] }
        
        var stats: [BrewLogDailyRatioStat] = []
        
        for (index, day) in daysWithData.enumerated() {
            let entriesForDay = grouped[day] ?? []
            let average = entriesForDay.map(\.ratio).reduce(0, +) / Double(entriesForDay.count)
            
            let trend: BrewLogTrendBucket
            if index == 0 {
                trend = .notEnoughData
            } else {
                let previousDay = daysWithData[index - 1]
                let previousEntries = grouped[previousDay] ?? []
                let previousAverage = previousEntries.map(\.ratio).reduce(0, +) / Double(previousEntries.count)
                let difference = average - previousAverage
                
                if difference > 0.05 {
                    trend = .increase
                } else if difference < -0.05 {
                    trend = .decrease
                } else {
                    trend = .stable
                }
            }
            
            stats.append(
                BrewLogDailyRatioStat(
                    day: day,
                    averageRatio: average,
                    trendBucket: trend
                )
            )
        }
        
        return stats
    }
}