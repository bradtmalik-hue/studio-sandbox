import SwiftUI
import Charts

struct GrowthChartView: View {
    let records: [AppGrowthRecord]
    let month: Date

    private var monthRecords: [AppGrowthRecord] {
        records
            .filter { Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) }
            .sorted { $0.date < $1.date }
    }

    private var latestRecord: AppGrowthRecord? {
        monthRecords.max(by: { $0.date < $1.date })
    }

    private var latestRecords: [AppGrowthRecord] {
        guard let latest = latestRecord else { return [] }
        return [latest]
    }

    var body: some View {
        Group {
            if monthRecords.isEmpty {
                ContentUnavailableView(
                    "暂无曲线",
                    systemImage: "chart.xyaxis.line",
                    description: Text("这个月还没有身高体重记录，去「记一笔」添加吧。")
                )
            } else {
                chart
            }
        }
    }

    private var chart: some View {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: start) ?? month
        let end = nextMonth.addingTimeInterval(-1)

        return Chart {
            ForEach(monthRecords) { record in
                LineMark(
                    x: .value("日期", record.date),
                    y: .value("身高", record.heightCm),
                    series: .value("系列", "身高")
                )
                .foregroundStyle(Color.blue)
                .interpolationMethod(.catmullRom)
            }

            ForEach(monthRecords) { record in
                LineMark(
                    x: .value("日期", record.date),
                    y: .value("体重", record.weightKg),
                    series: .value("系列", "体重")
                )
                .foregroundStyle(Color.pink)
                .interpolationMethod(.catmullRom)
            }

            ForEach(latestRecords) { record in
                PointMark(
                    x: .value("日期", record.date),
                    y: .value("身高", record.heightCm)
                )
                .foregroundStyle(Color.blue)
                .symbolSize(80)
                .annotation(position: .top, alignment: .center) {
                    Text(String(format: "%.1f cm", record.heightCm))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                PointMark(
                    x: .value("日期", record.date),
                    y: .value("体重", record.weightKg)
                )
                .foregroundStyle(Color.pink)
                .symbolSize(80)
                .annotation(position: .bottom, alignment: .center) {
                    Text(String(format: "%.1f kg", record.weightKg))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .chartXScale(domain: start...end)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .padding()
    }
}