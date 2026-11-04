import SwiftUI
import Foundation

struct BrewLogStatsView: View {
    @EnvironmentObject private var store: BrewLogStore

    private let warmBackground = Color(red: 0.96, green: 0.94, blue: 0.91)
    private let warmCard = Color(red: 0.99, green: 0.97, blue: 0.93)
    private let warmBrown = Color(red: 0.45, green: 0.28, blue: 0.20)
    private let warmMutedBrown = Color(red: 0.63, green: 0.50, blue: 0.42)

    private var brews: [BrewLogBrew] {
        store.brews
    }

    private var totalBrewCount: Int {
        brews.count
    }

    private var thisWeekBrewCount: Int {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else {
            return 0
        }
        return brews.filter { weekInterval.contains($0.date) }.count
    }

    private var dailyTrend: [DailyRatio] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }
        .sorted()

        return days.map { day in
            let dayBrews = brews.filter { calendar.isDate($0.date, inSameDayAs: day) }
            let average = dayBrews.isEmpty ? 0 : dayBrews.map(\.ratio).reduce(0, +) / Double(dayBrews.count)
            return DailyRatio(id: day, date: day, averageRatio: average, count: dayBrews.count)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    countsSection
                    trendSection
                }
                .padding()
            }
            .background(warmBackground)
            .navigationTitle("统计")
        }
    }

    private var countsSection: some View {
        HStack(spacing: 16) {
            statCard(title: "总冲煮", value: totalBrewCount, unit: "杯")
            statCard(title: "本周", value: thisWeekBrewCount, unit: "杯")
        }
    }

    private func statCard(title: String, value: Int, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(warmMutedBrown)
            Text("\(value)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(warmBrown)
            Text(unit)
                .font(.caption)
                .foregroundStyle(warmMutedBrown.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(warmCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("一周粉水比趋势")
                .font(.headline)
                .foregroundStyle(warmBrown)

            if dailyTrend.allSatisfy({ $0.count == 0 }) {
                Text("本周暂无冲煮记录")
                    .font(.subheadline)
                    .foregroundStyle(warmMutedBrown)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 12) {
                    ForEach(dailyTrend) { day in
                        HStack {
                            Text(day.date, format: .dateTime.weekday(.abbreviated).month().day())
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(warmBrown)
                                .frame(width: 72, alignment: .leading)

                            Text(String(format: "1:%.1f", day.averageRatio))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(warmBrown)

                            Spacer()

                            Text("\(day.count) 杯")
                                .font(.caption)
                                .foregroundStyle(warmMutedBrown)
                        }
                        .padding(12)
                        .background(warmCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
        .padding()
        .background(warmCard.opacity(0.5), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct DailyRatio: Identifiable {
    let id: Date
    let date: Date
    let averageRatio: Double
    let count: Int
}