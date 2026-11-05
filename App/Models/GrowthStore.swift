import Foundation
import Combine

struct AppGrowthRecord: Identifiable, Codable {
    let id: UUID
    var date: Date
    var heightCm: Double
    var weightKg: Double

    init(id: UUID = UUID(), date: Date, heightCm: Double, weightKg: Double) {
        self.id = id
        self.date = date
        self.heightCm = heightCm
        self.weightKg = weightKg
    }
}

struct AppGrowthMonthGroup: Identifiable {
    let id: String
    let monthStart: Date
    let monthEnd: Date
    let records: [AppGrowthRecord]
}

final class AppGrowthStore: ObservableObject {
    @Published private(set) var records: [AppGrowthRecord] = []

    private let fileName = "growthRecords.json"

    private var fileURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName)
    }

    init() {
        load()
    }

    func add(_ record: AppGrowthRecord) {
        records.append(record)
        save()
    }

    func update(_ record: AppGrowthRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else {
            return
        }
        records[index] = record
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

    func record(withID id: UUID) -> AppGrowthRecord? {
        records.first { $0.id == id }
    }

    var groupedByMonth: [AppGrowthMonthGroup] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: records) { record -> Date in
            guard let interval = calendar.dateInterval(of: .month, for: record.date) else {
                return calendar.startOfDay(for: record.date)
            }
            return interval.start
        }

        return grouped
            .map { pair -> AppGrowthMonthGroup in
                let startDate = pair.key
                let monthRecords = pair.value.sorted { $0.date > $1.date }
                let endDate = calendar.dateInterval(of: .month, for: startDate)?.end ?? startDate
                let identifier = Self.monthIdentifier(for: startDate, calendar: calendar)

                return AppGrowthMonthGroup(
                    id: identifier,
                    monthStart: startDate,
                    monthEnd: endDate,
                    records: monthRecords
                )
            }
            .sorted { $0.monthStart > $1.monthStart }
    }

    private static func monthIdentifier(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        return String(format: "%04d-%02d", year, month)
    }

    private func save() {
        guard let fileURL else {
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(records)
            try data.write(to: fileURL)
        } catch {
            // Keep in-memory state even if persistence fails.
        }
    }

    private func load() {
        guard let fileURL else {
            return
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            records = []
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            records = try decoder.decode([AppGrowthRecord].self, from: data)
        } catch {
            records = []
        }
    }
}