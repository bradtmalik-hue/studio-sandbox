import Foundation
import Combine

struct AppQuote: Identifiable, Codable, Hashable {
    let id: UUID
    var bookTitle: String
    var author: String
    var pageNumber: Int
    var content: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        bookTitle: String,
        author: String,
        pageNumber: Int,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.bookTitle = bookTitle
        self.author = author
        self.pageNumber = pageNumber
        self.content = content
        self.createdAt = createdAt
    }
}

struct AppSettings: Codable, Equatable {
    var yearlyReadingGoal: Int
    var updatedAt: Date

    init(yearlyReadingGoal: Int = 12, updatedAt: Date = Date()) {
        self.yearlyReadingGoal = yearlyReadingGoal
        self.updatedAt = updatedAt
    }
}

struct DemoSeed {
    var now: Date
    var calendar: Calendar
    var sampleQuotes: [AppQuote]

    init(now: Date = Date(), calendar: Calendar = .current, sampleQuotes: [AppQuote] = []) {
        self.now = now
        self.calendar = calendar
        self.sampleQuotes = sampleQuotes
    }
}

final class AppStore: ObservableObject {
    @Published var quotes: [AppQuote]
    @Published var settings: AppSettings

    init(quotes: [AppQuote] = [], settings: AppSettings = AppSettings(yearlyReadingGoal: 0, updatedAt: Date())) {
        self.quotes = quotes
        self.settings = settings
    }
}

enum AppModels {
    static func loadSettings() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: "settings.json") else {
            return AppSettings(yearlyReadingGoal: 0, updatedAt: Date())
        }

        if let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return decoded
        }

        return AppSettings(yearlyReadingGoal: 0, updatedAt: Date())
    }

    static func saveSettings(_ settings: AppSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "settings.json")
        }
    }

    static func loadQuotes() -> [AppQuote] {
        guard let data = UserDefaults.standard.data(forKey: "quotes.json") else {
            return DemoSeed(now: Date(), calendar: .current, sampleQuotes: []).sampleQuotes
        }

        guard let decoded = try? JSONDecoder().decode([AppQuote].self, from: data) else {
            return DemoSeed(now: Date(), calendar: .current, sampleQuotes: []).sampleQuotes
        }

        guard !decoded.isEmpty else {
            return DemoSeed(now: Date(), calendar: .current, sampleQuotes: []).sampleQuotes
        }

        return decoded
    }
}
