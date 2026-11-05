import SwiftUI

enum AppChartStyle {
    // MARK: - 曲线颜色
    static let heightLineColor = Color(red: 0.22, green: 0.55, blue: 0.95)
    static let weightLineColor = Color(red: 0.95, green: 0.46, blue: 0.24)
    static let heightSymbolColor = Color(red: 0.22, green: 0.55, blue: 0.95)
    static let weightSymbolColor = Color(red: 0.95, green: 0.46, blue: 0.24)

    // MARK: - 网格与坐标轴
    static let gridLineColor = Color(red: 0.90, green: 0.92, blue: 0.95)
    static let axisLabelColor = Color(red: 0.35, green: 0.40, blue: 0.48)
    static let axisLabelFont: Font = .footnote

    // MARK: - 背景与卡片
    static let chartBackgroundColor = Color(red: 0.98, green: 0.99, blue: 1.0)
    static let cardBackgroundColor = Color(red: 0.97, green: 0.98, blue: 1.0)

    // MARK: - 图例
    static let legendTitleColor = Color(red: 0.20, green: 0.24, blue: 0.30)
    static let legendFont: Font = .subheadline

    // MARK: - 百分位参考线/带
    static let percentileLineColor = Color(red: 0.58, green: 0.64, blue: 0.72).opacity(0.7)
    static let percentileBandColor = Color(red: 0.22, green: 0.55, blue: 0.95).opacity(0.1)

    // MARK: - 尺寸
    static let lineWidth: CGFloat = 2.5
    static let symbolSize: CGFloat = 28
    static let chartHeight: CGFloat = 280
}