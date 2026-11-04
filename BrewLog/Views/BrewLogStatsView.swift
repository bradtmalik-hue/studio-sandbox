import Foundation
import SwiftUI
import Combine

struct BrewLogStatsView: View {
    @EnvironmentObject private var store: BrewLogStore

    private let warmBackground = Color(red: 0.96, green: 0.93, blue: 0.89)
    private let cardBackground = Color.white.opacity(0.65)
    private let accent = Color(red: 0.82, green: 0.36, blue: 0.22)

    var body: some View {
        NavigationStack {
            Group {
                if store.weeklyStats.isEmpty {
                    ContentUnavailableView(
                        "暂无冲煮数据",
                        systemImage: "chart.xyaxis.line",
                        description: Text("完成第一杯手冲后，这里会出现粉水比趋势。")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ratioTrendCard
                            dailyDetailCard
                        }
                        .padding()
                    }
                    .background(warmBackground)
                }
            }
            .navigationTitle("统计")
        }
    }

    private var ratioTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("最近一周粉水比趋势")
                .font(.headline)
                .foregroundColor(.primary)

            if store.weeklyStats.count > 1 {
                TrendChart(stats: store.weeklyStats)
                    .frame(height: 200)
            } else {
                Text("至少需要两次记录才能绘制趋势")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
        )
    }

    private var dailyDetailCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("逐日详情")
                .font(.headline)
                .foregroundColor(.primary)

            ForEach(Array(store.weeklyStats.enumerated()), id: \.offset) { _, stat in
                HStack {
                    Text(stat.day, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("1 : \(String(format: "%.2f", stat.ratio))")
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(accent)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.5))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
        )
    }
}

private struct TrendChart: View {
    let stats: [BrewLogWeeklyStat]

    private let accent = Color(red: 0.82, green: 0.36, blue: 0.22)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                chartGrid
                chartPath(in: geometry.size)
                chartPoints(in: geometry.size)
            }
        }
    }

    private var chartGrid: some View {
        VStack {
            ForEach(0..<4, id: \.self) { _ in
                Divider()
                Spacer()
            }
            Divider()
        }
        .opacity(0.15)
    }

    private func chartPath(in size: CGSize) -> some View {
        Path { path in
            let points = normalizedPoints(in: size)
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(
            accent,
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
    }

    private func chartPoints(in size: CGSize) -> some View {
        let points = normalizedPoints(in: size)
        return ForEach(0..<points.count, id: \.self) { index in
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)
                .position(points[index])
        }
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard stats.count > 1,
              let minRatio = stats.map(\.ratio).min(),
              let maxRatio = stats.map(\.ratio).max() else {
            return []
        }
        let range = maxRatio - minRatio
        let horizontalStep = size.width / CGFloat(stats.count - 1)
        let verticalPadding: CGFloat = 16
        let chartHeight = max(size.height - verticalPadding * 2, 0)

        return stats.enumerated().map { index, stat in
            let x = horizontalStep * CGFloat(index)
            let normalized = range > 0 ? (stat.ratio - minRatio) / range : 0.5
            let y = verticalPadding + chartHeight * (1 - CGFloat(normalized))
            return CGPoint(x: x, y: y)
        }
    }
}