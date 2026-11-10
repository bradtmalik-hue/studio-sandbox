// 设计 token：颜色、字号、间距、圆角只从这里取，页面里不许再写死数值。
// 由铸 App 生成。改配色只需要改这一个文件。
import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

enum AppTheme {
    static let bg         = Color(hex: 0x0B0C0E)
    static let surface    = Color(hex: 0x14161A)
    static let surfaceAlt = Color(hex: 0x1A1D22)
    static let stroke     = Color(hex: 0x262A31)
    static let text       = Color(hex: 0xF1F3F6)
    static let dim        = Color(hex: 0x868E9B)
    static let accent     = Color(hex: 0xE0A33E)
    static let accentSoft = Color(hex: 0x241C10)
    static let danger     = Color(hex: 0xD9534F)

    static let fontDisplay = Font.system(size: 34, weight: .bold)
    static let fontTitle   = Font.system(size: 24, weight: .semibold)
    static let fontSection = Font.system(size: 17, weight: .semibold)
    static let fontBody    = Font.system(size: 15, weight: .regular)
    static let fontLabel   = Font.system(size: 13, weight: .medium)
    static let fontCaption = Font.system(size: 12, weight: .regular)
    static let fontNumber  = Font.system(size: 30, weight: .semibold, design: .rounded)

    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 20
    static let s6: CGFloat = 24
    static let s8: CGFloat = 32
    static let s10: CGFloat = 40

    static let rSmall: CGFloat = 18
    static let rCard: CGFloat = 24
    static let rPill: CGFloat = 999

    static let shadowColor = Color.black.opacity(0.34)
    static let shadowRadius: CGFloat = 22
    static let shadowY: CGFloat = 10

    static let titleFont = fontTitle
    static let hasShadow = false
    static let hasStroke = true
    static let isDark = true
    static let colorScheme: ColorScheme = .dark
}
