import Foundation
import Combine

struct AppRun: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var distanceKm: Double
    var durationMinutes: Double = 0
    var note: String = ""
}

struct AppWeeklyVolume: Identifiable, Hashable {
    var id: Date { weekStart }
    var weekStart: Date
    var volumeKm: Double
}

final class AppRunStore: ObservableObject {
    @Published var runs: [AppRun] = []

    private let fileName = "runs.json"

    private var fileURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName)
    }

    init() {
        load()
    }

    func addRun(date: Date, distanceKm: Double, durationMinutes: Double, note: String) {
        let run = AppRun(
            date: date,
            distanceKm: distanceKm,
            durationMinutes: durationMinutes,
            note: note
        )
        runs.append(run)
        save()
    }

    func deleteRuns(at offsets: IndexSet) {
        runs.remove(atOffsets: offsets)
        save()
    }

    func deleteRun(_ run: AppRun) {
        guard let index = runs.firstIndex(where: { $0.id == run.id }) else { return }
        runs.remove(at: index)
        save()
    }

    func updateRun(_ run: AppRun) {
        guard let index = runs.firstIndex(where: { $0.id == run.id }) else { return }
        runs[index] = run
        save()
    }

    func weeklyVolumeForLastEightWeeks(now: Date = Date()) -> [AppWeeklyVolume] {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone.current

        guard let currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return []
        }

        let currentWeekStart = currentWeekInterval.start
        var volumes: [AppWeeklyVolume] = []

        for weekOffset in 0..<8 {
            let weekStart = calendar.date(
                byAdding: .day,
                value: -weekOffset * 7,
                to: currentWeekStart
            ) ?? currentWeekStart

            var volume: Double = 0
            for run in runs {
                guard let interval = calendar.dateInterval(of: .weekOfYear, for: run.date) else {
                    continue
                }
                if interval.start == weekStart {
                    volume += run.distanceKm
                }
            }

            volumes.append(AppWeeklyVolume(weekStart: weekStart, volumeKm: volume))
        }

        return volumes.sorted { $0.weekStart < $1.weekStart }
    }

    private func load() {
        guard let url = fileURL else { return }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            runs = try decoder.decode([AppRun].self, from: data)
        } catch {
            runs = []
        }
    }

    private func save() {
        guard let url = fileURL else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(runs)
            try data.write(to: url)
        } catch {
            print("Save failed: \(error)")
        }
    }
}