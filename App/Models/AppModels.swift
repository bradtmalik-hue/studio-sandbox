import Foundation
import Combine

struct AppGrowthRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var heightCM: Double
    var weightKG: Double
    var note: String

    init(id: UUID = UUID(), date: Date = Date(), heightCM: Double, weightKG: Double, note: String = "") {
        self.id = id
        self.date = date
        self.heightCM = heightCM
        self.weightKG = weightKG
        self.note = note
    }
}

final class AppGrowthStore: ObservableObject {
    @Published var childName: String = "宝宝"
    @Published var records: [AppGrowthRecord] = []

    private let fileName = "growth_records.json"
    private var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }

    private struct Snapshot: Codable {
        var childName: String
        var records: [AppGrowthRecord]
    }

    init() {
        load()
        if ProcessInfo.processInfo.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }

    var sortedRecords: [AppGrowthRecord] {
        records.sorted { $0.date < $1.date }
    }

    var latestRecord: AppGrowthRecord? {
        sortedRecords.last
    }

    func add(_ record: AppGrowthRecord) {
        records.append(record)
        save()
    }

    func update(_ record: AppGrowthRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
        save()
    }

    func delete(_ record: AppGrowthRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        save()
    }

    func load() {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let snapshot = try? decoder.decode(Snapshot.self, from: data) {
            childName = snapshot.childName
            records = snapshot.records
        }
    }

    func save() {
        guard let url = fileURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let snapshot = Snapshot(childName: childName, records: records)
        if let data = try? encoder.encode(snapshot) {
            try? data.write(to: url)
        }
    }
}

enum DemoSeed {
    static func apply(into store: AppGrowthStore) {
        guard ProcessInfo.processInfo.arguments.contains("-demoData") else { return }
        let calendar = Calendar.current
        let now = Date()
        let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let childName = "小糯米"

        func record(monthsAgo: Int, height: Double, weight: Double, note: String) -> AppGrowthRecord {
            let date = calendar.date(byAdding: .month, value: -monthsAgo, to: startOfCurrentMonth) ?? startOfCurrentMonth
            return AppGrowthRecord(date: date, heightCM: height, weightKG: weight, note: note)
        }

        store.childName = childName
        store.records = [
            record(monthsAgo: 9, height: 50.0, weight: 3.20, note: "出生记录"),
            record(monthsAgo: 8, height: 54.5, weight: 4.20, note: "满月体检"),
            record(monthsAgo: 7, height: 58.0, weight: 5.10, note: "2月龄"),
            record(monthsAgo: 6, height: 61.5, weight: 6.00, note: "3月龄"),
            record(monthsAgo: 5, height: 64.0, weight: 6.70, note: "4月龄"),
            record(monthsAgo: 4, height: 66.0, weight: 7.30, note: "5月龄"),
            record(monthsAgo: 3, height: 68.0, weight: 7.80, note: "6月龄"),
            record(monthsAgo: 2, height: 70.0, weight: 8.30, note: "7月龄"),
            record(monthsAgo: 1, height: 72.0, weight: 8.70, note: "8月龄"),
            record(monthsAgo: 0, height: 73.5, weight: 9.00, note: "9月龄")
        ]
        store.save()
    }
}
