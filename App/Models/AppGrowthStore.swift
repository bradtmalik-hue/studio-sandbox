import Foundation
import Combine

struct AppMonthSection: Identifiable {
    let id: Date
    let month: Date
    let records: [AppGrowthRecord]
    
    var title: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: month)
    }
}

final class AppGrowthStore: ObservableObject {
    @Published var records: [AppGrowthRecord] = []
    
    private let fileURL: URL
    
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        fileURL = docs.appendingPathComponent("growth_records.json")
        load()
    }
    
    // MARK: - CRUD
    
    func add(_ record: AppGrowthRecord) {
        records.append(record)
        sortRecords()
        save()
    }
    
    func update(_ record: AppGrowthRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
        sortRecords()
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
    
    func record(id: UUID) -> AppGrowthRecord? {
        records.first { $0.id == id }
    }
    
    // MARK: - Queries
    
    func records(for date: Date) -> [AppGrowthRecord] {
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }
    
    func records(inMonth month: Date) -> [AppGrowthRecord] {
        let calendar = Calendar.current
        let monthComps = calendar.dateComponents([.year, .month], from: month)
        return records.filter { record in
            let comps = calendar.dateComponents([.year, .month], from: record.date)
            return comps.year == monthComps.year && comps.month == monthComps.month
        }
        .sorted { $0.date > $1.date }
    }
    
    // MARK: - Grouping
    
    var monthSections: [AppMonthSection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record -> Date in
            let comps = calendar.dateComponents([.year, .month], from: record.date)
            return calendar.date(from: comps) ?? record.date
        }
        return grouped.keys.sorted(by: >).map { month in
            AppMonthSection(
                id: month,
                month: month,
                records: grouped[month]!.sorted { $0.date > $1.date }
            )
        }
    }
    
    // MARK: - Persistence
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL)
        } catch {
            // 本地文件写入失败时保持当前内存数据，不打断用户操作。
        }
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([AppGrowthRecord].self, from: data)
            records = decoded
            sortRecords()
        } catch {
            records = []
        }
    }
    
    private func sortRecords() {
        records.sort { $0.date > $1.date }
    }
}