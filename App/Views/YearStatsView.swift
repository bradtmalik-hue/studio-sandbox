import SwiftUI
import Foundation

struct YearStatsView: View {
    @EnvironmentObject private var store: AppFilmLibraryStore
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    private var allYears: [Int] {
        let years = Set(store.records.map { Calendar.current.component(.year, from: $0.watchDate) })
        let currentYear = Calendar.current.component(.year, from: Date())
        var result = years
        result.insert(currentYear)
        return result.sorted(by: >)
    }

    private var selectedYearRecords: [AppFilmRecord] {
        store.records.filter { Calendar.current.component(.year, from: $0.watchDate) == selectedYear }
    }

    private var totalCount: Int {
        selectedYearRecords.count
    }

    private var averageRating: Double {
        guard totalCount > 0 else { return 0 }
        let total = selectedYearRecords.reduce(0) { $0 + $1.starRating }
        return Double(total) / Double(totalCount)
    }

    private var monthlyCounts: [Int] {
        var counts = Array(repeating: 0, count: 12)
        for record in selectedYearRecords {
            let month = Calendar.current.component(.month, from: record.watchDate)
            if month >= 1 && month <= 12 {
                counts[month - 1] += 1
            }
        }
        return counts
    }

    private var maxMonthlyCount: Int {
        max(monthlyCounts.max() ?? 0, 1)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        yearPickerSection

                        if totalCount == 0 {
                            emptyState
                        } else {
                            summaryCards
                            monthlyRhythmSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("年度统计")
        }
    }

    private var yearPickerSection: some View {
        Picker("选择年份", selection: $selectedYear) {
            ForEach(allYears, id: \.self) { year in
                Text(String(year)).tag(year)
            }
        }
        .pickerStyle(.menu)
    }

    private var summaryCards: some View {
        HStack(spacing: 16) {
            AppYearStatCard(
                title: "总片数",
                value: "\(totalCount)",
                systemImage: "film.fill"
            )
            AppYearStatCard(
                title: "平均星级",
                value: String(format: "%.1f", averageRating),
                systemImage: "star.fill"
            )
        }
    }

    private var monthlyRhythmSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("月度观影节奏")
                .font(.headline)

            ForEach(0..<12, id: \.self) { index in
                HStack {
                    Text(monthShortName(index))
                        .font(.subheadline.monospacedDigit())
                        .frame(width: 36, alignment: .leading)
                        .foregroundColor(.secondary)

                    ProgressView(value: Double(monthlyCounts[index]), total: Double(maxMonthlyCount))
                        .tint(.accentColor)

                    Text("\(monthlyCounts[index])")
                        .font(.subheadline.monospacedDigit())
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("这一年还没有观影记录", systemImage: "film.stack")
        } description: {
            Text("去“记一部”添加第一部电影，开始积累你的电影记忆。")
        }
        .frame(maxWidth: .infinity, minHeight: 240)
    }

    private func monthShortName(_ index: Int) -> String {
        let months = [
            "1月", "2月", "3月", "4月", "5月", "6月",
            "7月", "8月", "9月", "10月", "11月", "12月"
        ]
        return months[index]
    }
}

private struct AppYearStatCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}