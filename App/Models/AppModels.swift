import Foundation
import Combine

struct AppFeedingRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var amountGrams: Double
    var note: String

    init(id: UUID = UUID(), date: Date, amountGrams: Double, note: String = "") {
        self.id = id
        self.date = date
        self.amountGrams = amountGrams
        self.note = note
    }
}

class AppFeedingStore: ObservableObject {
    @Published var records: [AppFeedingRecord] = []
    @Published var dailyTargetGrams: Double = 80.0

    private let recordsFileName = "AppFeedingRecords.json"
    private var recordsURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(recordsFileName)
    }

    init() {
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }

    func add(_ record: AppFeedingRecord) {
        records.append(record)
        save()
    }

    func delete(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        save()
    }

    func delete(_ record: AppFeedingRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    func update(_ record: AppFeedingRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
            save()
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(records)
            try data.write(to: recordsURL)
        } catch {
            print("保存失败: \(error)")
        }
    }

    private func load() {
        let url = recordsURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            records = try decoder.decode([AppFeedingRecord].self, from: data)
        } catch {
            print("读取失败: \(error)")
        }
    }
}

enum DemoSeed {
    static func apply(into store: AppFeedingStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }

        var demos: [AppFeedingRecord] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        func makeDate(daysAgo: Int, hour: Int, minute: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
        }

        demos.append(AppFeedingRecord(date: makeDate(daysAgo: 0, hour: 7, minute: 40), amountGrams: 35, note: "早餐：鸡肉罐头"))
        demos.append(AppFeedingRecord(date: makeDate(daysAgo: 0, hour: 18, minute: 30), amountGrams: 45, note: "晚餐：猫粮"))
        demos.append(AppFeedingRecord(date: makeDate(daysAgo: 1, hour: 7, minute: 55), amountGrams: 38, note: "早餐：鸡肉罐头"))
        demos.append(AppFeedingRecord(date: makeDate(daysAgo: 1, hour: 18, minute: 45), amountGrams: 42, note: "晚餐：猫粮"))
        demos.append(AppFeedingRecord(date: makeDate(daysAgo: 2, hour: 8, minute: 5), amountGrams: 30, note: "早餐：猫粮"))
        demos.append(AppFeedingRecord(date: makeDate(daysAgo: 2, hour: 19, minute: 10), amountGrams: 48, note: "晚餐：鸡胸肉"))
        demos.append(AppFeedingRecord(date: makeDate(daysAgo: 3, hour: 7, minute: 50), amountGrams: 36, note: "早餐：鸡肉罐头"))
        demos.append(AppFeedingRecord(date: makeDate(daysAgo: 3, hour: 18, minute: 20), amountGrams: 44, note: "晚餐：猫粮"))
        demos.append(AppFeedingRecord(date: makeDate(daysAgo: 4, hour: 8, minute: 15), amountGrams: 32, note: "早餐：猫粮"))
        demos.append(AppFeedingRecord(date: makeDate(daysAgo: 4, hour: 19, minute: 30), amountGrams: 46, note: "晚餐：鸡胸肉"))

        store.records = demos
        store.save()
    }
}