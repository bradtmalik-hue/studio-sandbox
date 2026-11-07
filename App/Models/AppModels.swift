import Foundation
import SwiftUI

struct AppDrinkRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var amount: Int
    var date: Date

    init(id: UUID = UUID(), amount: Int, date: Date) {
        self.id = id
        self.amount = amount
        self.date = date
    }
}

struct AppDataFile: Codable {
    var records: [AppDrinkRecord]
    var dailyGoal: Int
}

struct AppDayGroup: Identifiable {
    let id: Date
    let date: Date
    let records: [AppDrinkRecord]

    var total: Int {
        records.reduce(0) { $0 + $1.amount }
    }
}

final class AppStore: ObservableObject {
    @Published var records: [AppDrinkRecord]
    @Published var dailyGoal: Int

    init() {
        self.records = []
        self.dailyGoal = 2000
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }

    private var dataFileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("hydrationData.json")
    }

    var todayTotal: Int {
        let calendar = Calendar.current
        return records.filter { calendar.isDateInToday($0.date) }.reduce(0) { $0 + $1.amount }
    }

    var sortedRecords: [AppDrinkRecord] {
        records.sorted { $0.date > $1.date }
    }

    var dayGroups: [AppDayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { calendar.startOfDay(for: $0.date) }
        return grouped.map { date, records in
            AppDayGroup(id: date, date: date, records: records.sorted { $0.date > $1.date })
        }
        .sorted { $0.date > $1.date }
    }

    func add(amount: Int, date: Date = Date()) {
        let record = AppDrinkRecord(id: UUID(), amount: amount, date: date)
        records.append(record)
        save()
    }

    func delete(_ record: AppDrinkRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        save()
    }

    func clearAll() {
        records.removeAll()
        save()
    }

    func save() {
        let data = AppDataFile(records: records, dailyGoal: dailyGoal)
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: dataFileURL)
        } catch {
            _ = error
        }
    }

    func load() {
        let url = dataFileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let data = try decoder.decode(AppDataFile.self, from: jsonData)
            records = data.records
            dailyGoal = data.dailyGoal
        } catch {
            _ = error
        }
    }
}

enum DemoSeed {
    static func apply(into store: AppStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }

        store.records.removeAll()

        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)

        let demoData: [(daysAgo: Int, hour: Int, minute: Int, amount: Int)] = [
            (0, 9, 15, 250),
            (0, 11, 0, 250),
            (0, 13, 45, 350),
            (0, 16, 20, 250),
            (1, 9, 30, 300),
            (1, 12, 10, 250),
            (1, 15, 50, 300),
            (2, 10, 0, 250),
            (2, 14, 30, 400),
            (3, 8, 45, 300),
            (3, 18, 20, 250),
            (4, 11, 15, 350)
        ]

        for item in demoData {
            let baseDate = calendar.date(byAdding: .day, value: -item.daysAgo, to: todayStart)!
            let date = calendar.date(bySettingHour: item.hour, minute: item.minute, second: 0, of: baseDate)!
            store.add(amount: item.amount, date: date)
        }

        store.save()
    }
}