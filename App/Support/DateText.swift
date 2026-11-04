import Foundation

enum AppDateText {
    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let fullDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter
    }()

    static func fullDate(_ date: Date) -> String {
        fullDateFormatter.string(from: date)
    }

    static func shortDate(_ date: Date) -> String {
        shortDateFormatter.string(from: date)
    }

    static func time(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    static func fullDateTime(_ date: Date) -> String {
        fullDateTimeFormatter.string(from: date)
    }

    static func days(from start: Date, to end: Date = Date()) -> Int {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        return calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
    }

    static func relativeDayText(_ date: Date, now: Date = Date()) -> String {
        let dayCount = days(from: date, to: now)
        if dayCount == 0 {
            return "今天"
        }
        if dayCount == 1 {
            return "昨天"
        }
        if dayCount > 1 && dayCount <= 7 {
            return "\(dayCount)天前"
        }
        return fullDate(date)
    }

    static func restDaysText(roastDate: Date, now: Date = Date()) -> String {
        let dayCount = days(from: roastDate, to: now)
        if dayCount < 0 {
            return "烘焙日期在未来"
        }
        if dayCount == 0 {
            return "今日烘焙"
        }
        return "养豆 \(dayCount) 天"
    }

    static func beanAgeText(roastDate: Date, now: Date = Date()) -> String {
        let dayCount = days(from: roastDate, to: now)
        if dayCount < 0 {
            return "烘焙日期在未来"
        }
        if dayCount == 0 {
            return "今日烘焙，建议养豆 3 天"
        }
        switch dayCount {
        case 1...2:
            return "养豆 \(dayCount) 天，风味上升期"
        case 3...14:
            return "养豆 \(dayCount) 天，风味最佳期"
        case 15...30:
            return "养豆 \(dayCount) 天，风味稳定期"
        default:
            return "养豆 \(dayCount) 天，风味成熟"
        }
    }
}