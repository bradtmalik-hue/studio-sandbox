import SwiftUI
import Combine
import Foundation

struct AppStatsView: View {
    @EnvironmentObject var store: AppFilmStore
    
    private var yearStatistics: AppYearStatistics {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let yearFilms = store.films.filter { calendar.component(.year, from: $0.watchDate) == currentYear }
        let totalFilms = yearFilms.count
        let averageRating = totalFilms > 0 ? yearFilms.map(\.rating).reduce(0.0, +) / Double(totalFilms) : 0
        let monthlyCounts = (1...12).map { month in
            yearFilms.filter { calendar.component(.month, from: $0.watchDate) == month }.count
        }
        let sortedByDateDescending = yearFilms.sorted { $0.watchDate > $1.watchDate }
        let longestStreakWeeks = Self.longestStreakWeeks(in: sortedByDateDescending, calendar: calendar)
        return AppYearStatistics(
            year: currentYear,
            totalFilms: totalFilms,
            averageRating: averageRating,
            longestStreakWeeks: longestStreakWeeks,
            monthlyCounts: monthlyCounts
        )
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if yearStatistics.totalFilms == 0 {
                    emptyState
                } else {
                    statsContent
                }
            }
            .navigationTitle("统计")
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("今年还没有观影记录")
                .font(.headline)
            Text("去「记一部」添加你看过的电影吧")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var statsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("\(Calendar.current.component(.year, from: Date())) 年")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    AppStatCard(title: "总片数", value: "\(yearStatistics.totalFilms)", icon: "film")
                    AppStatCard(title: "平均星级", value: String(format: "%.1f", yearStatistics.averageRating), icon: "star.fill")
                }
                
                streakCard
                monthlyRhythmCard
            }
            .padding()
        }
    }
    
    private var streakCard: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundColor(.primary)
            Text("连续观影周")
            Spacer()
            Text("\(yearStatistics.longestStreakWeeks) 周")
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var monthlyRhythmCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("月度观影节奏")
                .font(.headline)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<12, id: \.self) { month in
                    let count = yearStatistics.monthlyCounts[month]
                    VStack {
                        Text("\(count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Rectangle()
                            .fill(count > 0 ? Color.primary : Color.secondary.opacity(0.3))
                            .frame(height: height(for: count))
                            .cornerRadius(4)
                        Text("\(month + 1)月")
                            .font(.caption2)
                    }
                }
            }
            .frame(height: 140, alignment: .bottom)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func height(for count: Int) -> CGFloat {
        let maxCount = max(yearStatistics.monthlyCounts.max() ?? 1, 1)
        if count == 0 { return 8 }
        return max(20, CGFloat(count) / CGFloat(maxCount) * 100)
    }
    
    private static func longestStreakWeeks(in films: [AppFilmRecord], calendar: Calendar) -> Int {
        let weekStarts = Set(films.compactMap { calendar.dateInterval(of: .weekOfYear, for: $0.watchDate)?.start })
        let sortedWeeks = weekStarts.sorted()
        guard let first = sortedWeeks.first else { return 0 }
        
        var longest = 1
        var current = 1
        var previous = first
        
        for week in sortedWeeks.dropFirst() {
            if let next = calendar.date(byAdding: .weekOfYear, value: 1, to: previous),
               calendar.isDate(next, inSameDayAs: week) {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
            previous = week
        }
        
        return longest
    }
}

struct AppStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AppStatsView_Previews: PreviewProvider {
    static var previews: some View {
        AppStatsView()
            .environmentObject(AppFilmStore())
    }
}