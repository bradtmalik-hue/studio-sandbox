import Foundation
import Combine

struct AppPracticeRecord: Identifiable, Codable {
    let id: UUID
    var date: Date
    var durationMinutes: Double
    var note: String
}

class AppStore: ObservableObject {
    @Published var records: [AppPracticeRecord] = []
    
    private let fileName = "practice_records.json"
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
    
    init() {
        load()
    }
    
    func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([AppPracticeRecord].self, from: data)
            records = decoded
        } catch {
            records = []
        }
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL)
        } catch {
            print("保存失败: \(error)")
        }
    }
    
    func add(date: Date = Date(), durationMinutes: Double, note: String = "") {
        let newRecord = AppPracticeRecord(id: UUID(), date: date, durationMinutes: durationMinutes, note: note)
        records.append(newRecord)
        save()
    }
    
    func delete(id: UUID) {
        records.removeAll { $0.id == id }
        save()
    }
    
    func update(id: UUID, date: Date, durationMinutes: Double, note: String) {
        if let index = records.firstIndex(where: { $0.id == id }) {
            records[index] = AppPracticeRecord(id: id, date: date, durationMinutes: durationMinutes, note: note)
            save()
        }
    }
    
    // MARK: - 统计
    
    func startOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
    
    func recordsForMonth(containing date: Date) -> [AppPracticeRecord] {
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
    }
    
    func totalDuration(for records: [AppPracticeRecord]) -> Double {
        records.reduce(0) { $0 + $1.durationMinutes }
    }
    
    func totalDurationThisMonth(for date: Date = Date()) -> Double {
        totalDuration(for: recordsForMonth(containing: date))
    }
    
    func totalDaysThisMonth(for date: Date = Date()) -> Int {
        let monthRecords = recordsForMonth(containing: date)
        let calendar = Calendar.current
        let uniqueDays = Set(monthRecords.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }
    
    func dailySummaries(for records: [AppPracticeRecord]) -> [(date: Date, minutes: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { calendar.startOfDay(for: $0.date) }
        let sortedDates = grouped.keys.sorted()
        return sortedDates.map { date in
            let total = grouped[date]?.reduce(0) { $0 + $1.durationMinutes } ?? 0
            return (date, total)
        }
    }
    
    func monthlySummaries() -> [(month: Date, minutes: Double)] {
        let grouped = Dictionary(grouping: records) { startOfMonth(for: $0.date) }
        let sortedMonths = grouped.keys.sorted()
        return sortedMonths.map { monthStart in
            let total = grouped[monthStart]?.reduce(0) { $0 + $1.durationMinutes } ?? 0
            return (monthStart, total)
        }
    }
}