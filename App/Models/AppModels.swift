import Foundation
import SwiftUI
import Combine

struct AppWaterRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var amount: Double
    var container: String
    var note: String

    init(id: UUID = UUID(), date: Date, amount: Double, container: String, note: String) {
        self.id = id
        self.date = date
        self.amount = amount
        self.container = container
        self.note = note
    }
}

final class AppHydrationStore: ObservableObject {
    @Published var records: [AppWaterRecord] = []
    static let dailyGoal: Double = 2000

    private let fileURL: URL

    init() {
        fileURL = Self.defaultFileURL()
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply()
        }
    }

    private static func defaultFileURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("hydration_records.json")
    }

    func addRecord(amount: Double, container: String, note: String, date: Date = Date()) {
        let record = AppWaterRecord(id: UUID())
        records.append(record)
        records.sort { $0.date > $1.date }
        save()
    }

    func deleteRecord(_ record: AppWaterRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    var todayRecords: [AppWaterRecord] {
        let calendar = Calendar.current
        return records.filter { calendar.isDateInToday($0.date) }
            .sorted { $0.date > $1.date }
    }

    var todayTotal: Double {
        todayRecords.reduce(0) { $0 + $1.amount }
    }

    var remainingToday: Double {
        max(0, Self.dailyGoal - todayTotal)
    }

    var dailyAverageLast7Days: Double {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        guard let startOf7DaysAgo = calendar.date(byAdding: .day, value: -6, to: startOfToday) else { return 0 }
        let last7Records = records.filter { $0.date >= startOf7DaysAgo && $0.date < Date() }
        let days = Set(last7Records.map { calendar.startOfDay(for: $0.date) }).count
        guard days > 0 else { return 0 }
        return last7Records.reduce(0) { $0 + $1.amount } / Double(days)
    }

    var reachDaysLast7Days: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        guard let startOf7DaysAgo = calendar.date(byAdding: .day, value: -6, to: startOfToday) else { return 0 }
        var count = 0
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday) else { continue }
            let dayRecords = records.filter { calendar.isDate($0.date, inSameDayAs: day) }
            let total = dayRecords.reduce(0) { $0 + $1.amount }
            if total >= Self.dailyGoal {
                count += 1
            }
        }
        return count
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(records)
            try data.write(to: fileURL)
        } catch {
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            records = try decoder.decode([AppWaterRecord].self, from: data)
            records.sort { $0.date > $1.date }
        } catch {
            records = []
        }
    }
}

enum DemoSeed {
    static let seedFlagID = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!

    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
        let store = AppHydrationStore()
        DemoSeed.apply()
    }

    static func apply(into store: AppHydrationStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }
        if store.records.contains(where: { $0.id == seedFlagID }) { return }

        let calendar = Calendar.current
        func makeDate(_ dayOffset: Int, _ hour: Int, _ minute: Int) -> Date {
            let base = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        let seeds: [AppWaterRecord] = [
            AppWaterRecord(id: seedFlagID),
            AppWaterRecord(id: UUID()),
            AppWaterRecord(id: UUID()),
            AppWaterRecord(id: UUID()),
            AppWaterRecord(id: UUID()),
            AppWaterRecord(id: UUID()),
            AppWaterRecord(id: UUID()),
            AppWaterRecord(id: UUID()),
            AppWaterRecord(id: UUID()),
            AppWaterRecord(id: UUID()),
            AppWaterRecord(id: UUID())
        ]

        store.records.removeAll()
        store.records.append(contentsOf: seeds)
        store.records.sort { $0.date > $1.date }
        store.save()
    }
}