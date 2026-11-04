import Foundation
import Combine

class AppBrewStore: ObservableObject {
    @Published private(set) var records: [AppBrewRecord] = []

    private let fileName = "AppBrewRecords.json"

    private var fileURL: URL? {
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return directory.appendingPathComponent(fileName)
    }

    init() {
        load()
    }

    var sortedRecords: [AppBrewRecord] {
        records.sorted { $0.date > $1.date }
    }

    var bestRecord: AppBrewRecord? {
        records.first { $0.isBest }
    }

    func add(_ record: AppBrewRecord) {
        records.append(record)
        save()
    }

    func delete(_ record: AppBrewRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        let sorted = sortedRecords
        offsets.forEach { index in
            let record = sorted[index]
            records.removeAll { $0.id == record.id }
        }
        save()
    }

    func toggleBest(for record: AppBrewRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else {
            return
        }

        if records[index].isBest {
            records[index].isBest = false
        } else {
            for i in records.indices {
                records[i].isBest = false
            }
            records[index].isBest = true
        }

        save()
    }

    func markBest(_ record: AppBrewRecord) {
        guard records.contains(where: { $0.id == record.id }) else {
            return
        }

        for index in records.indices {
            records[index].isBest = (records[index].id == record.id)
        }
        save()
    }

    func parameters(for record: AppBrewRecord) -> (dose: Double, water: Double, temperature: Double, duration: TimeInterval) {
        (dose: record.dose, water: record.waterAmount, temperature: record.waterTemperature, duration: record.totalDuration)
    }

    private func load() {
        guard let url = fileURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            records = try decoder.decode([AppBrewRecord].self, from: data)
        } catch {
            print("加载冲煮记录失败: \(error.localizedDescription)")
        }
    }

    private func save() {
        guard let url = fileURL else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(records)
            try data.write(to: url)
        } catch {
            print("保存冲煮记录失败: \(error.localizedDescription)")
        }
    }
}