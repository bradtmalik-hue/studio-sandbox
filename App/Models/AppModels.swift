import Foundation
import Combine

enum AppWaterType: String, Codable, CaseIterable, Identifiable {
    case freshwater
    case saltwater
    var id: String { rawValue }
}

enum AppLogKind: String, Codable, CaseIterable, Identifiable {
    case waterChange
    case feeding
    var id: String { rawValue }
}

struct AppTank: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var volumeLiters: Double
    var waterType: AppWaterType
    var createdAt: Date
    var notes: String
    var localizedCaseInsensitiveContains: String = ""
}

struct AppLogEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var tankID: UUID
    var kind: AppLogKind
    var quantity: Double
    var note: String
    var date: Date
}

class AppStore: ObservableObject {
    @Published var tanks: [AppTank] = [] {
        didSet { saveTanks() }
    }
    @Published var logs: [AppLogEntry] = [] {
        didSet { saveLogs() }
    }

    private var tanksURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("tanks.json")
    }

    var logsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("logs.json")
    }

    init() {
        load()
        #if DEBUG
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
        #endif
    }

    func addTank(_ tank: AppTank) {
        tanks.append(tank)
    }

    func updateTank(_ tank: AppTank) {
        guard let index = tanks.firstIndex(where: { $0.id == tank.id }) else { return }
        tanks[index] = tank
    }

    func deleteTank(id: UUID) {
        tanks.removeAll { $0.id == id }
        logs.removeAll { $0.tankID == id }
    }

    func addLog(_ entry: AppLogEntry) {
        logs.append(entry)
    }

    func deleteLog(id: UUID) {
        logs.removeAll { $0.id == id }
    }

    func logs(forTank tankID: UUID) -> [AppLogEntry] {
        logs.filter { $0.tankID == tankID }.sorted { $0.date < $1.date }
    }

    func logs(inMonth month: Date, calendar: Calendar = .current) -> [AppLogEntry] {
        logs.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
            .sorted { $0.date < $1.date }
    }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func saveTanks() {
        do {
            let data = try makeEncoder().encode(tanks)
            try data.write(to: tanksURL)
        } catch {
        }
    }

    private func saveLogs() {
        do {
            let data = try makeEncoder().encode(logs)
            try data.write(to: logsURL)
        } catch {
        }
    }

    private func load() {
        let decoder = makeDecoder()
        if let tankData = try? Data(contentsOf: tanksURL),
           let decodedTanks = try? decoder.decode([AppTank].self, from: tankData) {
            tanks = decodedTanks
        }
        if let logData = try? Data(contentsOf: logsURL),
           let decodedLogs = try? decoder.decode([AppLogEntry].self, from: logData) {
            logs = decodedLogs
        }
    }
}

#if DEBUG
enum DemoSeed {
    static func apply(into store: AppStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }
        let calendar = Calendar.current
        let now = Date()
        func daysAgo(_ days: Int, from date: Date = Date()) -> Date {
            calendar.date(byAdding: .day, value: -days, to: date) ?? date
        }
        func hoursAgo(_ hours: Int, from date: Date = Date()) -> Date {
            calendar.date(byAdding: .hour, value: -hours, to: date) ?? date
        }

        let freshwater = AppWaterType.freshwater
        let saltwater = AppWaterType.saltwater

        let mainTank = AppTank(id: UUID(), name: "Main Display", volumeLiters: 120, waterType: freshwater, createdAt: daysAgo(45, from: now), notes: "Community tank", localizedCaseInsensitiveContains: "")
        let nanoTank = AppTank(id: UUID(), name: "Nano Shrimp", volumeLiters: 30, waterType: freshwater, createdAt: daysAgo(20, from: now), notes: "Planted tank", localizedCaseInsensitiveContains: "")
        let reefTank = AppTank(id: UUID(), name: "Reef", volumeLiters: 200, waterType: saltwater, createdAt: daysAgo(60, from: now), notes: "Soft corals", localizedCaseInsensitiveContains: "")
        store.tanks = [mainTank, nanoTank, reefTank]

        let mainID = mainTank.id
        let nanoID = nanoTank.id
        let reefID = reefTank.id

        var entries: [AppLogEntry] = []
        entries.append(AppLogEntry(id: UUID(), tankID: mainID, kind: .waterChange, quantity: 30, note: "Weekly 25%", date: daysAgo(14, from: now)))
        entries.append(AppLogEntry(id: UUID(), tankID: mainID, kind: .feeding, quantity: 2, note: "Morning flakes", date: daysAgo(13, from: now)))
        entries.append(AppLogEntry(id: UUID(), tankID: nanoID, kind: .waterChange, quantity: 8, note: "RO water", date: daysAgo(12, from: now)))
        entries.append(AppLogEntry(id: UUID(), tankID: reefID, kind: .waterChange, quantity: 40, note: "Salt mix", date: daysAgo(10, from: now)))
        entries.append(AppLogEntry(id: UUID(), tankID: mainID, kind: .feeding, quantity: 3, note: "Evening pellets", date: daysAgo(8, from: now)))
        entries.append(AppLogEntry(id: UUID(), tankID: nanoID, kind: .feeding, quantity: 1, note: "Shrimp pellets", date: daysAgo(7, from: now)))
        entries.append(AppLogEntry(id: UUID(), tankID: reefID, kind: .feeding, quantity: 2, note: "Frozen mysis", date: daysAgo(6, from: now)))
        entries.append(AppLogEntry(id: UUID(), tankID: mainID, kind: .waterChange, quantity: 30, note: "Biweekly 25%", date: daysAgo(5, from: now)))
        entries.append(AppLogEntry(id: UUID(), tankID: nanoID, kind: .feeding, quantity: 1, note: "Spirulina", date: daysAgo(3, from: now)))
        entries.append(AppLogEntry(id: UUID(), tankID: reefID, kind: .waterChange, quantity: 35, note: "Trace elements", date: daysAgo(2, from: now)))
        entries.append(AppLogEntry(id: UUID(), tankID: mainID, kind: .feeding, quantity: 2, note: "Fasting day skip", date: daysAgo(1, from: now)))
        entries.append(AppLogEntry(id: UUID(), tankID: nanoID, kind: .waterChange, quantity: 8, note: "Top off", date: hoursAgo(5, from: now)))
        store.logs = entries
    }
}
#endif