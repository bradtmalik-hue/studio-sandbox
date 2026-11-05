import Foundation

enum AppFormatters {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()

    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.currencyCode = "CNY"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    static func dateString(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    static func monthYearString(_ date: Date) -> String {
        monthFormatter.string(from: date)
    }

    static func monthDayString(_ date: Date) -> String {
        monthDayFormatter.string(from: date)
    }

    static func currencyString(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? "¥0.00"
    }

    static func decimalString(_ value: Double) -> String {
        decimalFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func integerString(_ value: Double) -> String {
        integerFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    static func mileageString(_ kilometers: Double) -> String {
        "\(integerString(kilometers)) 公里"
    }

    static func litersString(_ liters: Double) -> String {
        "\(decimalString(liters)) 升"
    }

    static func fuelEconomyString(_ litersPer100Kilometers: Double) -> String {
        "\(decimalString(litersPer100Kilometers)) 升/百公里"
    }

    static func perKilometerCostString(_ costPerKilometer: Double) -> String {
        "\(currencyString(costPerKilometer))/公里"
    }
}