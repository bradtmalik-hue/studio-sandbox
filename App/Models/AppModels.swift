import Foundation
import Combine

struct AppWaterEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var amountML: Int
    var date: Date
    var note: String
}

struct AppSettings: Codable {
    var dailyGoalML: Int
}

struct AppDaySummary: Identifiable, Hashable {
    let date: Date
    let totalML: Int
    let entries: [AppWaterEntry]

    var id: Date { date }
}

final class AppStore: ObservableObject {
    @Published var entries: [AppWaterEntry] = []
    @Published var dailyGoalML: Int = 2000

    private let entriesFileName = "water_entries.json"
    private let settingsFileName = "water_settings.json"

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var entriesFileURL: URL {
        documentsDirectory.appendingPathComponent(entriesFileName)
    }

    private var settingsFileURL: URL {
        documentsDirectory.appendingPathComponent(settingsFileName)
    }

    init() {
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply()
        }
    }

    var todayEntries: [AppWaterEntry] {
        let cal = Calendar.current
        return entries
            .filter { cal.isDateInToday($0.date) }
            .sorted { $0.date > $1.date }
    }

    var totalToday: Int {
        todayEntries.reduce(0) { $0 + $1.amountML }
    }

    var todayProgress: Double {
        guard dailyGoalML > 0 else { return 0 }
        return min(Double(totalToday) / Double(dailyGoalML), 1.0)
    }

    var lastEntryDate: Date? {
        entries.map(\.date).max()
    }

    var historyDays: [AppDaySummary] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: entries) { cal.startOfDay(for: $0.date) }
        return grouped
            .map { day, dayEntries in
                AppDaySummary(
                    date: day,
                    totalML: dayEntries.reduce(0) { $0 + $1.amountML },
                    entries: dayEntries.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.date > $1.date }
    }

    func addEntry(amountML: Int, date: Date = Date(), note: String = "") {
        let entry = AppWaterEntry(id: UUID(), amountML: amountML, date: date, note: note)
        entries.append(entry)
        entries.sort { $0.date > $1.date }
        save()
    }

    func updateEntry(_ entry: AppWaterEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index] = entry
        entries.sort { $0.date > $1.date }
        save()
    }

    func deleteEntry(_ entry: AppWaterEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func deleteEntries(at offsets: IndexSet, in list: [AppWaterEntry]) {
        let idsToDelete = offsets.map { list[$0].id }
        entries.removeAll { idsToDelete.contains($0.id) }
        save()
    }

    func clearAllEntries() {
        entries.removeAll()
        save()
    }

    func setDailyGoal(_ ml: Int) {
        dailyGoalML = max(0, ml)
        save()
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let entriesData = try encoder.encode(entries)
            try entriesData.write(to: entriesFileURL)

            let settings = AppSettings(dailyGoalML: dailyGoalML)
            let settingsData = try encoder.encode(settings)
            try settingsData.write(to: settingsFileURL)
        } catch {
            // 保存失败时保持内存数据，便于界面继续使用
        }
    }

    private func load() {
        let decoder = JSONDecoder()

        if let entriesData = try? Data(contentsOf: entriesFileURL),
           let loadedEntries = try? decoder.decode([AppWaterEntry].self, from: entriesData) {
            entries = loadedEntries.sorted { $0.date > $1.date }
        }

        if let settingsData = try? Data(contentsOf: settingsFileURL),
           let loadedSettings = try? decoder.decode(AppSettings.self, from: settingsData) {
            dailyGoalML = loadedSettings.dailyGoalML
        }
    }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
    }

    static func apply(into store: AppStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }

        let now = Date()
        let cal = Calendar.current
        let amounts = [250, 300, 500, 350, 200, 400, 250, 350, 500, 300]
        let notes = [
            "晨起一杯",
            "上午补水",
            "午餐后",
            "下午茶",
            "运动后",
            "晚餐前",
            "睡前补水",
            "会议间隙",
            "外出回来",
            "餐前饮水"
        ]

        var demoEntries: [AppWaterEntry] = []
        for i in 0..<10 {
            let dayOffset = i % 7
            let baseDate = cal.date(byAdding: .day, value: -dayOffset, to: now) ?? now
            let hour = 7 + (i * 2) % 15
            let minute = (i * 13) % 60
            let date = cal.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate) ?? baseDate

            let entry = AppWaterEntry(
                id: UUID(),
                amountML: amounts[i % amounts.count],
                date: date,
                note: notes[i % notes.count]
            )
            demoEntries.append(entry)
        }

        store.entries = demoEntries.sorted { $0.date > $1.date }
        store.dailyGoalML = 2200
        store.save()
    }
}