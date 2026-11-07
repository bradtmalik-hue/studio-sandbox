import Foundation
import Combine
import SwiftUI

struct AppWaterRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var amount: Int
    var date: Date
    var kind: AppDrinkKind

    init(id: UUID = UUID(), amount: Int, date: Date = Date(), kind: AppDrinkKind = .water) {
        self.id = id
        self.amount = amount
        self.date = date
        self.kind = kind
    }
}

enum AppDrinkKind: String, Codable, CaseIterable, Identifiable {
    case water = "白水"
    case tea = "茶"
    case coffee = "咖啡"
    case juice = "果汁"
    case milk = "牛奶"

    var id: String { rawValue }
}

struct AppDayGroup: Identifiable {
    let id: Date
    let day: Date
    let records: [AppWaterRecord]
    let total: Int
}

struct AppDayStats: Identifiable {
    let id: Date
    let day: Date
    let total: Int
}

final class AppStore: ObservableObject {
    @Published var records: [AppWaterRecord]
    @Published var dailyGoal: Int
    @Published var defaultCupAmount: Int

    private var storageURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("hydration_records.json")
    }

    init() {
        records = []
        dailyGoal = 2000
        defaultCupAmount = 250
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply()
        }
    }

    func add(amount: Int, date: Date = Date(), kind: AppDrinkKind = .water) {
        let record = AppWaterRecord(id: UUID(), amount: amount, date: date, kind: kind)
        records.append(record)
        save()
    }

    func delete(_ record: AppWaterRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    func save() {
        guard let url = storageURL else { return }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(records)
            try data.write(to: url)
        } catch {
        }
    }

    func load() {
        guard let url = storageURL, FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            records = try decoder.decode([AppWaterRecord].self, from: data)
        } catch {
            records = []
        }
    }

    var todayRecords: [AppWaterRecord] {
        let calendar = Calendar.current
        let now = Date()
        return records.filter { calendar.isDate($0.date, inSameDayAs: now) }
            .sorted { $0.date > $1.date }
    }

    var todayTotal: Int {
        todayRecords.reduce(0) { $0 + $1.amount }
    }

    var recentRecordDate: Date? {
        records.map(\.date).max()
    }

    var historyGroups: [AppDayGroup] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: records) { calendar.startOfDay(for: $0.date) }
        return groups.map { day, dayRecords in
            AppDayGroup(
                id: day,
                day: day,
                records: dayRecords.sorted { $0.date > $1.date },
                total: dayRecords.reduce(0) { $0 + $1.amount }
            )
        }
        .sorted { $0.day > $1.day }
    }

    var last7DaysStats: [AppDayStats] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let stats = (0..<7).map { offset -> AppDayStats in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let total = records
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.amount }
            return AppDayStats(id: day, day: day, total: total)
        }
        return stats.sorted { $0.day < $1.day }
    }

    var averageLast7Days: Double {
        let total = last7DaysStats.reduce(0) { $0 + $1.total }
        return Double(total) / 7.0
    }

    var goalMetCountLast7Days: Int {
        last7DaysStats.filter { $0.total >= dailyGoal }.count
    }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
    }

    static func apply(into store: AppStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }
        store.records = demoRecords()
        store.save()
    }

    static func demoRecords() -> [AppWaterRecord] {
        let calendar = Calendar.current

        func makeDate(dayOffset: Int, hour: Int, minute: Int) -> Date {
            let start = calendar.startOfDay(for: Date())
            let day = calendar.date(byAdding: .day, value: dayOffset, to: start) ?? start
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }

        return [
            AppWaterRecord(id: UUID(), amount: 250, date: makeDate(dayOffset: 0, hour: 7, minute: 10), kind: .water),
            AppWaterRecord(id: UUID(), amount: 250, date: makeDate(dayOffset: 0, hour: 9, minute: 0), kind: .tea),
            AppWaterRecord(id: UUID(), amount: 250, date: makeDate(dayOffset: 0, hour: 11, minute: 30), kind: .water),
            AppWaterRecord(id: UUID(), amount: 250, date: makeDate(dayOffset: 0, hour: 14, minute: 20), kind: .water),
            AppWaterRecord(id: UUID(), amount: 250, date: makeDate(dayOffset: -1, hour: 8, minute: 5), kind: .water),
            AppWaterRecord(id: UUID(), amount: 250, date: makeDate(dayOffset: -1, hour: 12, minute: 40), kind: .coffee),
            AppWaterRecord(id: UUID(), amount: 250, date: makeDate(dayOffset: -2, hour: 9, minute: 15), kind: .water),
            AppWaterRecord(id: UUID(), amount: 250, date: makeDate(dayOffset: -2, hour: 13, minute: 0), kind: .water),
            AppWaterRecord(id: UUID(), amount: 250, date: makeDate(dayOffset: -3, hour: 10, minute: 0), kind: .water),
            AppWaterRecord(id: UUID(), amount: 250, date: makeDate(dayOffset: -3, hour: 15, minute: 30), kind: .tea),
            AppWaterRecord(id: UUID(), amount: 250, date: makeDate(dayOffset: -4, hour: 8, minute: 0), kind: .water),
            AppWaterRecord(id: UUID(), amount: 250, date: makeDate(dayOffset: -5, hour: 10, minute: 30), kind: .water)
        ]
    }
}