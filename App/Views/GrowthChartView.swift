import Foundation
import SwiftUI
import Charts

struct GrowthChartView: View {
    @EnvironmentObject private var store: AppGrowthStore
    @State private var metric: GrowthMetric = .height

    private var sortedRecords: [AppGrowthRecord] {
        store.records.sorted { $0.date < $1.date }
    }

    private var monthlyPoints: [MonthlyGrowthPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sortedRecords) { record -> Date in
            calendar.dateInterval(of: .month, for: record.date)?.start ?? record.date
        }

        let points = grouped.map { month, records in
            let values = records.map { metric == .height ? $0.height : $0.weight }
            let average = values.reduce(0.0, +) / Double(values.count)
            return MonthlyGrowthPoint(month: month, value: average)
        }

        return points.sorted { $0.month < $1.month }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedRecords.isEmpty {
                    ContentUnavailableView()
                } else {
                    VStack(spacing: 16) {
                        Picker("指标", selection: $metric) {
                            Text("身高").tag(GrowthMetric.height)
                            Text("体重").tag(GrowthMetric.weight)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        Chart(monthlyPoints) { point in
                            LineMark(
                                x: .value("月份", point.month, unit: .month),
                                y: .value(metric == .height ? "身高（厘米）" : "体重（公斤）", point.value)
                            )
                            .foregroundStyle(metric == .height ? Color.blue : Color.green)
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("月份", point.month, unit: .month),
                                y: .value(metric == .height ? "身高（厘米）" : "体重（公斤）", point.value)
                            )
                            .foregroundStyle(metric == .height ? Color.blue : Color.green)
                        }
                        .chartYAxisLabel(metric == .height ? "厘米" : "公斤")
                        .chartXAxisLabel("月份")
                        .frame(height: 320)
                        .padding()

                        if let latest = sortedRecords.last {
                            Text("最新记录：\(latest.date.formatted(date: .abbreviated, time: .omitted)) \(latest.height, specifier: "%.1f") cm / \(latest.weight, specifier: "%.1f") kg")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("成长曲线")
            .background(Color(.systemGroupedBackground))
        }
    }
}

private enum GrowthMetric: String {
    case height, weight
}

private struct MonthlyGrowthPoint: Identifiable {
    let month: Date
    let value: Double

    var id: Date { month }
}