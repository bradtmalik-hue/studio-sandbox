import Foundation
import Combine

struct AppGrowthRecord: Identifiable, Codable {
    let id: UUID
    var date: Date
    var height: Double
    var weight: Double
    var note: String?

    init(id: UUID = UUID(), date: Date, height: Double, weight: Double, note: String? = nil) {
        self.id = id
        self.date = date
        self.height = height
        self.weight = weight
        self.note = note
    }
}

struct AppData: Codable {
    var childName: String
    var birthDate: Date
    var records: [AppGrowthRecord]
}

final class AppStore: ObservableObject {
    @Published var childName: String = ""
    @Published var birthDate: Date = Date()
    @Published var records: [AppGrowthRecord] = []

    private static let fileName = "growth_records.json"
    private var dataURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Self.fileName)
    }

    init() {
        load()
    }

    func addRecord(_ record: AppGrowthRecord) {
        records.append(record)
        save()
    }

    func updateRecord(_ record: AppGrowthRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
            save()
        }
    }

    func deleteRecord(_ record: AppGrowthRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    func deleteRecords(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        save()
    }

    func save() {
        let data = AppData(childName: childName, birthDate: birthDate, records: records)
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: dataURL)
        } catch {
            print("保存失败: \(error)")
        }
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let jsonData = try Data(contentsOf: dataURL)
            let data = try decoder.decode(AppData.self, from: jsonData)
            childName = data.childName
            birthDate = data.birthDate
            records = data.records
        } catch {
            childName = ""
            birthDate = Date()
            records = []
        }
    }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
        let store = AppStore()
        guard store.records.isEmpty else { return }

        store.childName = "小禾"
        let birthDate = Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date()
        store.birthDate = birthDate

        let demoEntries: [(ageMonths: Int, height: Double, weight: Double)] = [
            (0, 50.0, 3.4),
            (2, 58.0, 5.5),
            (4, 64.0, 7.0),
            (6, 68.0, 8.0),
            (9, 72.0, 9.0),
            (12, 76.0, 10.0),
            (15, 80.0, 10.8),
            (18, 83.0, 11.5),
            (21, 86.0, 12.0),
            (24, 89.0, 12.5),
            (30, 93.0, 13.2),
            (36, 96.0, 14.0)
        ]

        store.records = demoEntries.map { entry in
            let recordDate = Calendar.current.date(byAdding: .month, value: entry.ageMonths, to: birthDate) ?? Date()
            return AppGrowthRecord(
                date: recordDate,
                height: entry.height,
                weight: entry.weight,
                note: nil
            )
        }

        store.save()
    }
}