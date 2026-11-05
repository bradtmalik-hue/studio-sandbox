import SwiftUI
import Foundation

enum AppPalette {
    // MARK: - Colors
    static let background = Color(red: 1.0, green: 1.0, blue: 1.0)
    static let cardBackground = Color(red: 0.97, green: 0.98, blue: 0.97)
    static let accent = Color(red: 0.07, green: 0.32, blue: 0.25)
    static let accentDark = Color(red: 0.04, green: 0.22, blue: 0.17)
    static let accentLight = Color(red: 0.86, green: 0.93, blue: 0.90)
    static let textPrimary = Color(red: 0.15, green: 0.19, blue: 0.16)
    static let textSecondary = Color(red: 0.42, green: 0.47, blue: 0.44)
    static let separator = Color(red: 0.91, green: 0.93, blue: 0.91)
    static let chartGrid = Color(red: 0.93, green: 0.95, blue: 0.93)
    static let chartFill = Color(red: 0.07, green: 0.32, blue: 0.25).opacity(0.12)
    static let shadow = Color.black.opacity(0.06)

    // MARK: - Radius
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 10

    // MARK: - Fonts
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 16, weight: .regular, design: .rounded)
    static let subheadline = Font.system(size: 14, weight: .medium, design: .rounded)
    static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
    static let numeric = Font.system(size: 20, weight: .bold, design: .rounded)
    static let chartAnnotation = Font.system(size: 11, weight: .medium, design: .rounded)

    // MARK: - Units
    static let heightUnit = "cm"
    static let weightUnit = "kg"

    // MARK: - Formatting
    static let heightFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    static let weightFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.setLocalizedDateFormatFromTemplate("yyyyMMMM")
        return formatter
    }()

    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter
    }()

    static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter
    }()

    static func formattedHeight(_ value: Double) -> String {
        let number = NSNumber(value: value)
        return heightFormatter.string(from: number) ?? String(format: "%.1f", value)
    }

    static func formattedWeight(_ value: Double) -> String {
        let number = NSNumber(value: value)
        return weightFormatter.string(from: number) ?? String(format: "%.2f", value)
    }
}