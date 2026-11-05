import Foundation

extension Date {
    /// 月份标识，如 "2025-04"，用于按月分组。
    var appMonthKey: String {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        let year = components.year ?? 0
        let month = components.month ?? 0
        return String(format: "%04d-%02d", Int32(year), Int32(month))
    }

    /// 当月第一天。
    var appMonthStart: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? calendar.startOfDay(for: self)
    }

    /// 当前日期所在月份的完整时间区间。区间末尾为下个月第一天的起始时刻。
    var appMonthInterval: DateInterval {
        let calendar = Calendar.current
        let start = appMonthStart
        let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        return DateInterval(start: start, end: nextMonthStart)
    }

    /// 当月最后一秒，便于使用 date <= appMonthEnd 包含整月记录。
    var appMonthEnd: Date {
        appMonthInterval.end.addingTimeInterval(-1)
    }

    /// 统一显示日期，如中文环境“2025年4月9日”。
    var appDisplayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// 统一显示月份，如中文环境“2025年4月”。
    var appDisplayMonth: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yMMMM")
        return formatter.string(from: self)
    }

    /// 短月份显示，如中文环境“4月”，适合图表坐标轴。
    var appDisplayShortMonth: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        return formatter.string(from: self)
    }

    /// 返回向前或向后移动指定数量月份的日期。
    func appAddingMonths(_ count: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: count, to: self) ?? self
    }

    /// 从 "yyyy-MM" 月份标识创建该月第一天的日期。
    static func appDate(fromMonthKey key: String) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              (1...12).contains(month) else {
            return nil
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        return Calendar.current.date(from: components)
    }
}