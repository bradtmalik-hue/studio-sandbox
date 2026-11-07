import SwiftUI
import Combine

struct AppDrinkRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var amount: Int
}

class AppStore: ObservableObject {
    @Published var records: [AppDrinkRecord] = []
    private let fileURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent("drinkRecords.json")
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            records = try JSONDecoder().decode([AppDrinkRecord].self, from: data)
        } catch {
            records = []
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL)
        } catch {
        }
    }

    func add(amount: Int, date: Date = Date()) {
        let record = AppDrinkRecord(id: UUID(), date: date, amount: amount)
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

    var todayRecords: [AppDrinkRecord] {
        let calendar = Calendar.current
        return records.filter { calendar.isDateInToday($0.date) }
            .sorted { $0.date < $1.date }
    }

    var historyGroups: [(date: Date, records: [AppDrinkRecord])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { calendar.startOfDay(for: $0.date) }
        return grouped.keys.sorted(by: >).map { date in
            (date: date, records: grouped[date]!.sorted { $0.date < $1.date })
        }
    }

    var last7DaysRecords: [AppDrinkRecord] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date()))!
        return records.filter { $0.date >= startDate }
    }

    var averageLast7Days: Double {
        let total = last7DaysRecords.reduce(0) { $0 + $1.amount }
        return last7DaysRecords.isEmpty ? 0 : Double(total) / 7.0
    }

    var daysReachedGoalLast7Days: Int {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date()))!
        let grouped = Dictionary(grouping: last7DaysRecords) { calendar.startOfDay(for: $0.date) }
        return grouped.filter { dayRecords in
            let total = dayRecords.value.reduce(0) { $0 + $1.amount }
            return total >= 2000
        }.count
    }
}

enum DemoSeed {
    static func apply(into store: AppStore) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        func date(daysAgo: Int, hour: Int, minute: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: startOfToday)!
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
        }

        let samples: [AppDrinkRecord] = [
            AppDrinkRecord(id: UUID(), date: date(daysAgo: 0, hour: 9, minute: 30), amount: 250),
            AppDrinkRecord(id: UUID(), date: date(daysAgo: 0, hour: 12, minute: 15), amount: 500),
            AppDrinkRecord(id: UUID(), date: date(daysAgo: 1, hour: 8, minute: 0), amount: 250),
            AppDrinkRecord(id: UUID(), date: date(daysAgo: 1, hour: 12, minute: 30), amount: 500),
            AppDrinkRecord(id: UUID(), date: date(daysAgo: 1, hour: 18, minute: 0), amount: 300),
            AppDrinkRecord(id: UUID(), date: date(daysAgo: 2, hour: 7, minute: 30), amount: 300),
            AppDrinkRecord(id: UUID(), date: date(daysAgo: 2, hour: 10, minute: 0), amount: 200),
            AppDrinkRecord(id: UUID(), date: date(daysAgo: 2, hour: 14, minute: 0), amount: 400),
            AppDrinkRecord(id: UUID(), date: date(daysAgo: 2, hour: 20, minute: 0), amount: 500),
            AppDrinkRecord(id: UUID(), date: date(daysAgo: 3, hour: 8, minute: 0), amount: 250),
            AppDrinkRecord(id: UUID(), date: date(daysAgo: 3, hour: 13, minute: 0), amount: 250),
            AppDrinkRecord(id: UUID(), date: date(daysAgo: 3, hour: 19, minute: 0), amount: 250),
        ]
        store.records = samples
        store.save()
    }
}