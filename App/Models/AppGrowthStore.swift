import Foundation
import Combine

struct AppGrowthMonthSection: Identifiable {
    let id: String
    let monthKey: String
    let title: String
    let records: [AppGrowthRecord]
}

final class AppGrowthStore: ObservableObject {
    static let shared = AppGrowthStore()

    @Published private(set) var records: [AppGrowthRecord] = []

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private static let monthTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yyyyMMMM")
        return formatter
    }()

    init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsDirectory.appendingPathComponent("growthRecords.json")
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        load()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            records = []
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try decoder.decode([AppGrowthRecord].self, from: data)
            records = decoded.sorted { $0.date < $1.date }
        } catch {
            records = []
        }
    }

    private func persist() {
        do {
            let data = try encoder.encode(records)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save growth records: \(error)")
        }
    }

    private func sortRecords() {
        records.sort { $0.date < $1.date }
    }

    // MARK: - CRUD

    func add(_ record: AppGrowthRecord) {
        records.append(record)
        sortRecords()
        persist()
    }

    func update(_ record: AppGrowthRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else {
            add(record)
            return
        }
        records[index] = record
        sortRecords()
        persist()
    }

    func delete(_ record: AppGrowthRecord) {
        records.removeAll { $0.id == record.id }
        persist()
    }

    func delete(id: UUID) {
        records.removeAll { $0.id == id }
        persist()
    }

    // MARK: - Queries

    var sortedByDateDescending: [AppGrowthRecord] {
        records.sorted { $0.date > $1.date }
    }

    var sortedByDateAscending: [AppGrowthRecord] {
        records.sorted { $0.date < $1.date }
    }

    var monthlySections: [AppGrowthMonthSection] {
        let grouped = Dictionary(grouping: records) { Self.monthKey(for: $0.date) }
        return grouped.map { key, values in
            let sortedValues = values.sorted { $0.date > $1.date }
            let firstDate = sortedValues.first?.date ?? Date()
            return AppGrowthMonthSection(
                id: key,
                monthKey: key,
                title: Self.monthTitleFormatter.string(from: firstDate),
                records: sortedValues
            )
        }
        .sorted { $0.monthKey > $1.monthKey }
    }

    // MARK: - Helpers

    static func monthKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        return String(format: "%04d-%02d", year, month)
    }

    // MARK: - Sample data

    static func sampleRecords() -> [AppGrowthRecord] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<6).reversed().map { offset in
            let date = calendar.date(byAdding: .month, value: -offset, to: now) ?? now
            let heightCm = 80.0 + Double(6 - offset) * 1.1
            let weightKg = 11.0 + Double(6 - offset) * 0.28
            return AppGrowthRecord(
                heightCm: heightCm,
                weightKg: weightKg,
                date: date,
                id: UUID()
            )
        }
    }

    func replaceRecordsWithSampleDataForPreview() {
        records = Self.sampleRecords()
        sortRecords()
        persist()
    }
}