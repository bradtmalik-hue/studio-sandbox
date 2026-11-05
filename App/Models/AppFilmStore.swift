import Foundation
import Combine

struct AppYearStatistics {
    let year: Int
    let totalFilms: Int
    let averageRating: Double
    let longestStreakWeeks: Int
    let monthlyCounts: [Int]
}

class AppFilmStore: ObservableObject {
    @Published var films: [AppFilmRecord] = []

    private static var dataFileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("films.json")
    }

    init() {
        load()
    }

    private func load() {
        let url = Self.dataFileURL
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            films = try decoder.decode([AppFilmRecord].self, from: data)
        } catch {
            films = []
        }
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(films)
            try data.write(to: Self.dataFileURL)
        } catch {
            print("Failed to save films: \(error.localizedDescription)")
        }
    }

    func add(_ film: AppFilmRecord) {
        films.append(film)
        save()
    }

    func update(_ film: AppFilmRecord) {
        guard let index = films.firstIndex(where: { $0.id == film.id }) else { return }
        films[index] = film
        save()
    }

    func delete(_ film: AppFilmRecord) {
        films.removeAll { $0.id == film.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        films.remove(atOffsets: offsets)
        save()
    }

    var sortedByDateDescending: [AppFilmRecord] {
        films.sorted { $0.watchDate > $1.watchDate }
    }

    func statistics(for year: Int) -> AppYearStatistics {
        let yearFilms = films.filter { Calendar.current.component(.year, from: $0.watchDate) == year }
        let totalFilms = yearFilms.count
        let averageRating = totalFilms == 0 ? 0 : yearFilms.reduce(0.0) { $0 + $1.rating } / Double(totalFilms)

        var monthlyCounts = Array(repeating: 0, count: 12)
        for film in yearFilms {
            let month = Calendar.current.component(.month, from: film.watchDate)
            guard month >= 1 && month <= 12 else { continue }
            monthlyCounts[month - 1] += 1
        }

        let longestStreakWeeks = Self.longestWeeklyStreak(dates: yearFilms.map(\.watchDate), year: year)

        return AppYearStatistics(
            year: year,
            totalFilms: totalFilms,
            averageRating: averageRating,
            longestStreakWeeks: longestStreakWeeks,
            monthlyCounts: monthlyCounts
        )
    }

    private static func longestWeeklyStreak(dates: [Date], year: Int) -> Int {
        guard !dates.isEmpty else { return 0 }
        let calendar = Calendar(identifier: .iso8601)
        var weeks: Set<Int> = []
        for date in dates {
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            guard let weekYear = components.yearForWeekOfYear, weekYear == year, let week = components.weekOfYear else { continue }
            weeks.insert(week)
        }
        guard !weeks.isEmpty else { return 0 }
        let sortedWeeks = weeks.sorted()
        var longest = 1
        var current = 1
        for index in 1..<sortedWeeks.count {
            if sortedWeeks[index] == sortedWeeks[index - 1] + 1 {
                current += 1
            } else {
                longest = max(longest, current)
                current = 1
            }
        }
        longest = max(longest, current)
        return longest
    }

    func randomFilm(for year: Int? = nil) -> AppFilmRecord? {
        if let year {
            let yearFilms = films.filter { Calendar.current.component(.year, from: $0.watchDate) == year }
            return yearFilms.randomElement()
        } else {
            return films.randomElement()
        }
    }
}