import Foundation
import Combine

struct AppYearStatistics: Equatable {
    let year: Int
    let totalCount: Int
    let averageRating: Double
}

final class AppFilmLibraryStore: ObservableObject {
    @Published var records: [FilmRecord] = []

    private let fileName = "filmRecords.json"

    private var fileURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent(fileName)
    }

    init() {
        load()
    }

    private func load() {
        let url = fileURL

        guard FileManager.default.fileExists(atPath: url.path) else {
            records = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            records = try decoder.decode([FilmRecord].self, from: data)
        } catch {
            records = []
        }
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(records)
            try data.write(to: fileURL)
        } catch {
            // Keep the in-memory list intact even if a write fails.
        }
    }

    func add(_ record: FilmRecord) {
        records.append(record)
        save()
    }

    func update(_ record: FilmRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
        save()
    }

    func delete(_ record: FilmRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        save()
    }

    func statistics(for year: Int) -> AppYearStatistics {
        let calendar = Calendar.current
        let yearRecords = records.filter { calendar.component(.year, from: $0.watchDate) == year }
        let totalCount = yearRecords.count
        let totalRating = yearRecords.reduce(0.0) { partialResult, record in
            partialResult + Double(record.rating)
        }
        let averageRating = totalCount == 0 ? 0 : totalRating / Double(totalCount)
        return AppYearStatistics(year: year, totalCount: totalCount, averageRating: averageRating)
    }
}