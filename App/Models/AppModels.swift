import Foundation
import Combine

struct AppWaterRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var amountML: Int
    var note: String

    init(id: UUID = UUID(), date: Date = Date(), amountML: Int, note: String = "") {
        self.id = id
        self.date = date
        self.amountML = amountML
        self.note = note
    }
}

struct AppDaySummary: Identifiable {
    var id: Date { date }
    let date: Date
    let totalML: Int
    let records: [AppWaterRecord]
}

private struct AppPersistedData: Codable {
    var records: [AppWaterRecord]
    var dailyGoalML: Int
}

final class AppStore: ObservableObject {
    @Published var records: [AppWaterRecord] = []
    @Published var dailyGoalML: Int = 2000

    private let fileURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documents.appendingPathComponent("water_records.json")
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply()
        }
    }

    var todayRecords: [AppWaterRecord] {
        records
            .filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date > $1.date }
    }

    var todayTotal: Int {
        todayRecords.reduce(0) { $0 + $1.amountML }
    }

    var latestRecordDate: Date? {
        records.map(\.date).max()
    }

    func daySummaries() -> [AppDaySummary] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { calendar.startOfDay(for: $0.date) }
        return grouped
            .map { date, dayRecords in
                AppDaySummary(
                    date: date,
                    totalML: dayRecords.reduce(0) { $0 + $1.amountML },
                    records: dayRecords.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.date > $1.date }
    }

    func addRecord(amountML: Int, date: Date = Date(), note: String = "") {
        let record = AppWaterRecord(id: UUID(), date: date, amountML: amountML, note: note)
        records.append(record)
        records.sort { $0.date > $1.date }
        save()
    }

    func deleteRecord(id: UUID) {
        records.removeAll { $0.id == id }
        save()
    }

    func updateGoal(_ goal: Int) {
        dailyGoalML = max(1, goal)
        save()
    }

    func clearAllRecords() {
        records.removeAll()
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(AppPersistedData.self, from: data)
            records = decoded.records
            dailyGoalML = decoded.dailyGoalML
        } catch {
            records = []
            dailyGoalML = 2000
        }
    }

    func save() {
        let persisted = AppPersistedData(records: records, dailyGoalML: dailyGoalML)
        do {
            let data = try JSONEncoder().encode(persisted)
            try data.write(to: fileURL)
        } catch {
        }
    }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
    }

    static func apply(into store: AppStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }

        let calendar = Calendar.current
        let now = Date()
        var demoRecords: [AppWaterRecord] = []

        func make(dayOffset: Int, hour: Int, minute: Int, amountML: Int, note: String) -> AppWaterRecord {
            let dayStart = calendar.startOfDay(for: now)
            let dayDate = calendar.date(byAdding: .day, value: -dayOffset, to: dayStart) ?? dayStart
            let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: dayDate) ?? dayDate
            return AppWaterRecord(id: UUID(), date: date, amountML: amountML, note: note)
        }

        demoRecords.append(make(dayOffset: 0, hour: 7, minute: 30, amountML: 250, note: "晨起一杯"))
        demoRecords.append(make(dayOffset: 0, hour: 9, minute: 40, amountML: 250, note: "早餐后"))
        demoRecords.append(make(dayOffset: 0, hour: 12, minute: 10, amountML: 250, note: "午餐后"))
        demoRecords.append(make(dayOffset: 0, hour: 15, minute: 0, amountML: 250, note: "午后补水"))
        demoRecords.append(make(dayOffset: 0, hour: 18, minute: 20, amountML: 250, note: "晚饭前"))
        demoRecords.append(make(dayOffset: 0, hour: 21, minute: 30, amountML: 250, note: "睡前一杯"))

        demoRecords.append(make(dayOffset: 1, hour: 8, minute: 10, amountML: 250, note: "晨起一杯"))
        demoRecords.append(make(dayOffset: 1, hour: 11, minute: 20, amountML: 250, note: "工作间隙"))
        demoRecords.append(make(dayOffset: 1, hour: 14, minute: 30, amountML: 250, note: "午后补水"))
        demoRecords.append(make(dayOffset: 1, hour: 20, minute: 10, amountML: 250, note: "散步后"))

        demoRecords.append(make(dayOffset: 2, hour: 9, minute: 5, amountML: 250, note: "运动后"))
        demoRecords.append(make(dayOffset: 2, hour: 16, minute: 45, amountML: 250, note: "下午茶"))

        demoRecords.append(make(dayOffset: 3, hour: 7, minute: 55, amountML: 250, note: "晨起一杯"))
        demoRecords.append(make(dayOffset: 3, hour: 19, minute: 20, amountML: 250, note: "晚饭后"))

        store.records = demoRecords.sorted { $0.date > $1.date }
        store.dailyGoalML = 2000
        store.save()
    }
}