import Foundation

enum AppFormatters {
    static func monthTitle(for date: Date) -> String {
        date.formatted(.dateTime.year().month())
    }

    static func monthTitle(year: Int, month: Int) -> String {
        let calendar = Calendar.current
        guard let date = calendar.date(from: DateComponents(year: year, month: month)) else {
            return "\(year)年\(month)月"
        }
        return monthTitle(for: date)
    }

    static func dateString(for date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    static func heightString(_ centimeters: Double) -> String {
        String(format: "%.1f 厘米", centimeters)
    }

    static func weightString(_ kilograms: Double) -> String {
        String(format: "%.2f 公斤", kilograms)
    }
}