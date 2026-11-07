import Foundation
import Combine

struct AppWaterRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var amountMl: Int
    var date: Date

    init(id: UUID = UUID(), amountMl: Int, date: Date) {
        self.id = id
        self.amountMl = amountMl
        self.date = date
    }
}

final class AppStore: ObservableObject {
    @Published var records: [AppWaterRecord] = []
    @Published var dailyGoalMl: Int = 2000

    private var saveURL: URL? {
        let manager = FileManager.default
        guard let directory = manager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return directory.appendingPathComponent("hydration_records.json")
    }

    init() {
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply()
        }
    }

    func load() {
        guard let url = saveURL, let data = try? Data(contentsOf: url) else {
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let savedRecords = try? decoder.decode([AppWaterRecord].self, from: data) {
            records = savedRecords
        }
    }

    func save() {
        guard let url = saveURL else {
            return
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(records) {
            try? data.write(to: url)
        }
    }
}

enum DemoSeed {
    static func apply() {
    }

    static func apply(into store: AppStore) {
        guard CommandLine.arguments.contains("-demoData") else {
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        let sampleData: [(daysAgo: Int, hour: Int, minute: Int, amountMl: Int)] = [
            (0, 8, 5, 250),
            (0, 10, 15, 300),
            (0, 13, 45, 500),
            (0, 16, 20, 250),
            (1, 9, 30, 350),
            (1, 12, 10, 400),
            (2, 11, 50, 600),
            (3, 15, 25, 750),
            (4, 18, 40, 250),
            (5, 7, 55, 300),
            (6, 14, 0, 450),
            (6, 19, 35, 500)
        ]

        var seededRecords: [AppWaterRecord] = []

        for item in sampleData {
            let dayDate = calendar.date(byAdding: .day, value: -item.daysAgo, to: startOfToday) ?? startOfToday
            let date = calendar.date(bySettingHour: item.hour, minute: item.minute, second: 0, of: dayDate) ?? dayDate
            let record = AppWaterRecord(id: UUID(), amountMl: item.amountMl, date: date)
            seededRecords.append(record)
        }

        store.records = seededRecords
        store.save()
    }
}