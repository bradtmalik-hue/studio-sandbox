import Foundation
import Combine

struct AppBookGroup: Identifiable {
    var id: String { bookName }
    let bookName: String
    let quotes: [AppQuote]
}

struct AppDayGroup: Identifiable {
    var id: Date { date }
    let date: Date
    let quotes: [AppQuote]
}

final class AppQuoteStore: ObservableObject {
    @Published var quotes: [AppQuote] = []

    private let fileName = "quotes.json"

    private var fileURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(fileName)
    }

    init() {
        load()
    }

    func add(_ quote: AppQuote) {
        quotes.append(quote)
        save()
    }

    func delete(_ quote: AppQuote) {
        quotes.removeAll { $0.id == quote.id }
        save()
    }

    var bookGroups: [AppBookGroup] {
        let grouped = Dictionary(grouping: quotes, by: \.bookTitle)
        return grouped
            .map { bookName, quotes in
                AppBookGroup(
                    bookName: bookName,
                    quotes: quotes.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.bookName.localizedStandardCompare($1.bookName) == .orderedAscending }
    }

    var dayGroups: [AppDayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: quotes) { quote -> Date in
            calendar.startOfDay(for: quote.date)
        }
        return grouped
            .map { date, quotes in
                AppDayGroup(
                    date: date,
                    quotes: quotes.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.date > $1.date }
    }

    func search(keyword: String) -> [AppQuote] {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return quotes
            .filter { quote in
                quote.text.localizedCaseInsensitiveContains(trimmed) ||
                quote.bookTitle.localizedCaseInsensitiveContains(trimmed) ||
                quote.thoughts.localizedCaseInsensitiveContains(trimmed)
            }
            .sorted { $0.date > $1.date }
    }

    func quotesOn(_ date: Date) -> [AppQuote] {
        let calendar = Calendar.current
        return quotes
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(quotes)
            try data.write(to: fileURL)
        } catch {
            print("保存失败：\(error.localizedDescription)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            quotes = try JSONDecoder().decode([AppQuote].self, from: data)
        } catch {
            print("加载失败：\(error.localizedDescription)")
        }
    }
}