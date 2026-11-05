import Foundation

enum AppDateFormatter {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current
        return calendar
    }()
    
    private static func makeFormatter(dateFormat: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .current
        return formatter
    }
    
    static func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    static func dayKey(for date: Date) -> String {
        makeFormatter(dateFormat: "yyyy-MM-dd").string(from: date)
    }
    
    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }
    
    static func timelineTitle(for date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "今天"
        }
        if calendar.isDateInYesterday(date) {
            return "昨天"
        }
        return makeFormatter(dateFormat: "yyyy年M月d日").string(from: date)
    }
    
    static func mediumDate(for date: Date) -> String {
        makeFormatter(dateFormat: "yyyy年M月d日").string(from: date)
    }
    
    static func shortDate(for date: Date) -> String {
        makeFormatter(dateFormat: "M月d日").string(from: date)
    }
    
    static func monthTitle(for date: Date) -> String {
        makeFormatter(dateFormat: "yyyy年M月").string(from: date)
    }
    
    static func shortTime(for date: Date) -> String {
        makeFormatter(dateFormat: "HH:mm").string(from: date)
    }
}