import Foundation
import SwiftUI
import Combine

struct AppWaterRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var amountMl: Double
}

struct AppWaterData: Codable {
    var dailyGoalMl: Double
    var records: [AppWaterRecord]
}

class AppStore: ObservableObject {
    @Published var records: [AppWaterRecord] = []
    @Published var dailyGoalMl: Double = 2000

    private let saveURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        saveURL = docs.appendingPathComponent("AppWaterData.json")
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL) else { return }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(AppWaterData.self, from: data)
            self.records = decoded.records
            self.dailyGoalMl = decoded.dailyGoalMl
        } catch {
            print("Load failed: \(error)")
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(AppWaterData(dailyGoalMl: dailyGoalMl, records: records))
            try data.write(to: saveURL)
        } catch {
            print("Save failed: \(error)")
        }
    }

    func addRecord(amountMl: Double, date: Date = Date()) {
        let record = AppWaterRecord(id: UUID(), date: date, amountMl: amountMl)
        records.append(record)
        save()
    }

    func deleteRecord(id: UUID) {
        records.removeAll { $0.id == id }
        save()
    }

    func updateRecord(id: UUID, amountMl: Double, date: Date) {
        if let index = records.firstIndex(where: { $0.id == id }) {
            records[index].amountMl = amountMl
            records[index].date = date
            save()
        }
    }

    func totalAmount(for date: Date) -> Double {
        let calendar = Calendar.current
        return records
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .reduce(0) { $0 + $1.amountMl }
    }

    func records(for date: Date) -> [AppWaterRecord] {
        let calendar = Calendar.current
        return records
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }
}

enum DemoSeed {
    static func apply(into store: AppStore) {
        var demoRecords: [AppWaterRecord] = []
        let calendar = Calendar.current
        let now = Date()
        let amounts: [Double] = [350, 500, 250, 400, 600, 300, 450, 550, 200, 500, 350, 400]
        let daysAgo: [Int] = [0, 0, 1, 1, 2, 2, 3, 3, 4, 5, 6, 7]

        for (index, amount) in amounts.enumerated() {
            let days = daysAgo[index]
            let dayOffset = -days
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let hour = [8, 12, 20][index % 3]
            let minute = [15, 0, 45][index % 3]
            guard let finalDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) else { continue }
            demoRecords.append(AppWaterRecord(id: UUID(), date: finalDate, amountMl: amount))
        }
        store.records = demoRecords.sorted(by: { $0.date > $1.date })
        store.dailyGoalMl = 2000
        store.save()
    }
}