import SwiftUI
import Foundation

struct AppGrowthChartView: View {
    @EnvironmentObject private var store: AppGrowthStore

    private static let heightColor = Color(red: 0.10, green: 0.45, blue: 0.35)
    private static let weightColor = Color(red: 0.95, green: 0.55, blue: 0.20)

    private var monthlyData: [AppMonthlyGrowth] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.records) { record -> Date in
            let components = calendar.dateComponents([.year, .month], from: record.date)
            return calendar.date(from: components) ?? record.date
        }
        return grouped.keys.sorted().map { month in
            let records = grouped[month] ?? []
            let totalHeight = records.reduce(0) { $0 + $1.height }
            let totalWeight = records.reduce(0) { $0 + $1.weight }
            let count = Double(records.count)
            return AppMonthlyGrowth(
                month: month,
                averageHeight: count > 0 ? totalHeight / count : 0,
                averageWeight: count > 0 ? totalWeight / count : 0
            )
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if monthlyData.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            legend
                            heightChart
                            weightChart
                            latestSummary
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("成长曲线")
            .background(Color(uiColor: .systemBackground))
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("还没有成长记录", systemImage: "chart.xyaxis.line")
        } description: {
            Text("记下第一笔身高体重，曲线会在这里长出来。")
        }
    }

    private var legend: some View {
        HStack(spacing: 20) {
            Label("身高", systemImage: "circle.fill")
                .foregroundStyle(AppGrowthChartView.heightColor)
            Label("体重", systemImage: "circle.fill")
                .foregroundStyle(AppGrowthChartView.weightColor)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }

    private var heightChart: some View {
        let points = monthlyData.map {
            AppGrowthChartView.AppChartPoint(month: $0.month, value: $0.averageHeight)
        }
        return AppGrowthLineChartView()
    }

    private var weightChart: some View {
        let points = monthlyData.map {
            AppGrowthChartView.AppChartPoint(month: $0.month, value: $0.averageWeight)
        }
        return AppGrowthLineChartView()
    }

    private var latestSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最近一个月平均")
                .font(.headline)
            if let last = monthlyData.last {
                Text("身高 \(last.averageHeight, specifier: "%.1f") cm · 体重 \(last.averageWeight, specifier: "%.1f") kg")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private struct AppMonthlyGrowth: Identifiable {
        let month: Date
        let averageHeight: Double
        let averageWeight: Double

        var id: Date { month }
    }

    fileprivate struct AppChartPoint: Identifiable {
        let month: Date
        let value: Double

        var id: Date { month }
    }
}

private struct AppGrowthLineChartView: View {
    let title: String
    let points: [AppGrowthChartView.AppChartPoint]
    let lineColor: Color
    let unit: String

    private let minValue: Double
    private let maxValue: Double

    init(title: String, points: [AppGrowthChartView.AppChartPoint], lineColor: Color, unit: String) {
        self.title = title
        self.points = points
        self.lineColor = lineColor
        self.unit = unit
        let values = points.map { $0.value }
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 1
        let span = max(1, maxV - minV)
        self.minValue = minV - span * 0.1
        self.maxValue = maxV + span * 0.1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if let last = points.last {
                    Text("\(last.value, specifier: "%.1f") \(unit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if points.isEmpty {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                GeometryReader { proxy in
                    ZStack {
                        AppChartGridShape()
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 1)

                        if points.count > 1 {
                            AppLineShape(points: points, minValue: minValue, maxValue: maxValue)
                                .stroke(
                                    lineColor,
                                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                                )
                        }

                        ForEach(points.indices, id: \.self) { index in
                            Circle()
                                .fill(lineColor)
                                .frame(width: 8, height: 8)
                                .position(
                                    AppLineShape.position(
                                        for: points[index],
                                        index: index,
                                        total: points.count,
                                        in: proxy.size,
                                        minValue: minValue,
                                        maxValue: maxValue
                                    )
                                )
                        }
                    }
                }
                .frame(height: 180)

                HStack {
                    if let first = points.first {
                        Text(first.month, format: .dateTime.year().month())
                    }
                    Spacer()
                    if let last = points.last {
                        Text(last.month, format: .dateTime.year().month())
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct AppChartGridShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let horizontalLineCount = 3
        for index in 0...horizontalLineCount {
            let y = rect.minY + rect.height * CGFloat(index) / CGFloat(horizontalLineCount)
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        return path
    }
}

private struct AppLineShape: Shape {
    let points: [AppGrowthChartView.AppChartPoint]
    let minValue: Double
    let maxValue: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()

        guard points.count > 1 else {
            if let point = points.first {
                let x = rect.midX
                let y = yPosition(for: point.value, in: rect)
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x, y: y))
            }
            return path
        }

        let dx = rect.width / CGFloat(points.count - 1)
        for (index, point) in points.enumerated() {
            let x = rect.minX + CGFloat(index) * dx
            let y = yPosition(for: point.value, in: rect)
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }

    private func yPosition(for value: Double, in rect: CGRect) -> CGFloat {
        let span = maxValue - minValue
        guard span > 0 else { return rect.midY }
        let ratio = (value - minValue) / span
        return rect.maxY - CGFloat(ratio) * rect.height
    }

    static func position(
        for point: AppGrowthChartView.AppChartPoint,
        index: Int,
        total: Int,
        in size: CGSize,
        minValue: Double,
        maxValue: Double
    ) -> CGPoint {
        let span = maxValue - minValue
        let ratio = span > 0 ? (point.value - minValue) / span : 0.5
        let y = size.height - CGFloat(ratio) * size.height
        let x: CGFloat
        if total > 1 {
            x = CGFloat(index) * size.width / CGFloat(total - 1)
        } else {
            x = size.width / 2
        }
        return CGPoint(x: x, y: y)
    }
}