import Foundation

enum AppDateFormatter {
    // MARK: - 私有格式化器
    
    /// 用于按月分组的唯一标识，如 "2025-05"
    private static let monthKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .current
        return formatter
    }()
    
    /// 用于历史记录的分组标题，如 "2025年5月"
    private static let monthDisplayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .current
        return formatter
    }()
    
    /// 用于图表 X 轴标签，如 "5月"
    private static let axisLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .current
        return formatter
    }()
    
    /// 用于记录卡片上的日期显示，如 "2025年5月10日"
    private static let dateDisplayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .current
        return formatter
    }()
    
    // MARK: - 公开静态方法
    
    /// 生成用于按月分组的唯一标识
    static func monthKey(from date: Date) -> String {
        monthKeyFormatter.string(from: date)
    }
    
    /// 生成用于历史记录分组标题的显示文本
    static func monthDisplay(from date: Date) -> String {
        monthDisplayFormatter.string(from: date)
    }
    
    /// 生成用于图表 X 轴标签的简短文本
    static func axisLabel(from date: Date) -> String {
        axisLabelFormatter.string(from: date)
    }
    
    /// 生成记录卡片上完整日期显示的文本
    static func dateDisplay(from date: Date) -> String {
        dateDisplayFormatter.string(from: date)
    }
}