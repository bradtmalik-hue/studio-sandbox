import SwiftUI
import Charts

struct AppGrowthChartView: View {
    enum Metric: String, CaseIterable, Identifiable {
        case height
        case weight

        var id: String { rawValue }

        var title: String {
            switch self {
            case .height:
                return "Height (cm)"
            case .weight:
                return "Weight (kg)"
            }
        }

        func recordValue(_ record: AppGrowthRecord) -> Double {
            switch self {
            case .height:
                return record.heightCm
            case .weight:
                return record.weightKg
            }
        }
    }

    var store: AppGrowthStore? = nil
    var records: [AppGrowthRecord] = []
    var birthDate: Date? = nil

    @State private var metric: Metric = .height

    var body: some View {
        VStack(spacing: 16) {
            Picker("Measurement", selection: $metric) {
                ForEach(Metric.allCases) { metric in
                    Text(metric.title).tag(metric)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Chart {
                ForEach(percentileSeries(for: metric)) { series in
                    ForEach(series.points) { point in
                        LineMark(
                            x: .value("Age (months)", point.ageMonths),
                            y: .value(metric.title, point.value)
                        )
                        .foregroundStyle(by: .value("Percentile", series.title))
                    }
                }

                if let birthDate = birthDate {
                    ForEach(records) { record in
                        PointMark(
                            x: .value("Age (months)", ageMonths(for: record.date, birthDate: birthDate)),
                            y: .value(metric.title, metric.recordValue(record))
                        )
                        .foregroundStyle(Color.blue)
                        .symbolSize(50)
                    }
                }
            }
            .chartYAxisLabel(metric.title)
            .chartXAxisLabel("Age (months)")
            .padding()
        }
        .navigationTitle("Growth Chart")
    }

    private func percentileSeries(for metric: Metric) -> [AppPercentileSeries] {
        switch metric {
        case .height:
            return Self.heightPercentiles
        case .weight:
            return Self.weightPercentiles
        }
    }

    private func ageMonths(for date: Date, birthDate: Date) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.month], from: birthDate, to: date)
        return Double(components.month ?? 0)
    }

    private static let ages: [Double] = [0, 6, 12, 24, 36, 48, 60]

    private static func series(_ percentile: Double, values: [Double]) -> AppPercentileSeries {
        AppPercentileSeries(
            percentile: percentile,
            points: zip(ages, values).map { AppPercentilePoint(ageMonths: $0, value: $1) }
        )
    }

    static let heightPercentiles: [AppPercentileSeries] = [
        series(3, values: [46.3, 63.6, 71.3, 81.2, 89.6, 96.1, 101.9]),
        series(50, values: [49.9, 67.6, 75.7, 86.4, 95.3, 102.3, 108.6]),
        series(97, values: [53.4, 71.6, 80.2, 91.6, 101.1, 108.8, 115.8])
    ]

    static let weightPercentiles: [AppPercentileSeries] = [
        series(3, values: [2.5, 6.4, 8.0, 10.1, 11.8, 13.3, 14.8]),
        series(50, values: [3.3, 7.9, 9.6, 12.2, 14.3, 16.2, 18.0]),
        series(97, values: [4.3, 9.7, 11.5, 14.6, 17.1, 19.7, 22.2])
    ]
}