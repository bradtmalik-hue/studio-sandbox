import Foundation
import Combine

struct AppMonthlySection: Identifiable {
    let id: String
    let monthDate: Date
    let records: [AppGrowthRecord]
}

class AppGrowthStore: ObservableObject {
    @Published var records: [AppGrowthRecord] = []
    
    private let fileName = "growthRecords.json"
    private var fileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }
    
    private static let monthIDFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter
    }()
    
    init() {
        load()
    }
    
    // MARK: - Persistence
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            records = []
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            records = try decoder.decode([AppGrowthRecord].self, from: data)
            records.sort { $0.date > $1.date }
        } catch {
            records = []
        }
    }
    
    private func save() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(records)
            try data.write(to: fileURL)
        } catch {
            // Failed to save; keep in-memory data.
        }
    }
    
    // MARK: - CRUD
    
    func add(_ record: AppGrowthRecord) {
        records.append(record)
        records.sort { $0.date > $1.date }
        save()
    }
    
    func update(_ record: AppGrowthRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
        records.sort { $0.date > $1.date }
        save()
    }
    
    func delete(_ record: AppGrowthRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }
    
    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            records.remove(at: index)
        }
        save()
    }
    
    // MARK: - Grouping
    
    func monthlySections() -> [AppMonthlySection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record -> Date in
            calendar.date(from: calendar.dateComponents([.year, .month], from: record.date)) ?? record.date
        }
        let sortedDates = grouped.keys.sorted(by: >)
        return sortedDates.map { date in
            let sectionRecords = grouped[date] ?? []
            return AppMonthlySection(
                id: Self.monthIDFormatter.string(from: date),
                monthDate: date,
                records: sectionRecords.sorted { $0.date > $1.date }
            )
        }
    }
    
    // MARK: - Helpers
    
    var latestRecord: AppGrowthRecord? {
        records.max(by: { $0.date < $1.date })
    }
}