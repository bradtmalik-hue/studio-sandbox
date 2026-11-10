import Foundation
import SwiftUI
import Combine

enum AppMaintenanceType: String, Codable, CaseIterable, Identifiable {
    case lubrication = "Lubrication"
    case cleaning = "Cleaning"
    case replacement = "Replacement"
    case adjustment = "Adjustment"
    case inspection = "Inspection"
    
    var id: String { rawValue }
}

struct AppMaintenanceRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var date: Date
    var type: AppMaintenanceType
    var component: String
    var notes: String
    var odometerKm: Double
    var cost: Double
    var durationMinutes: Int
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: AppMaintenanceType = .lubrication,
        component: String = "Chain",
        notes: String = "",
        odometerKm: Double = 0,
        cost: Double = 0,
        durationMinutes: Int = 15
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.component = component
        self.notes = notes
        self.odometerKm = odometerKm
        self.cost = cost
        self.durationMinutes = durationMinutes
    }
}

struct AppReminderSettings: Codable, Equatable {
    var enabled: Bool
    var intervalKm: Double
    var lastServiceOdometerKm: Double
    var remindBeforeKm: Double
    
    init(
        enabled: Bool = true,
        intervalKm: Double = 300,
        lastServiceOdometerKm: Double = 0,
        remindBeforeKm: Double = 20
    ) {
        self.enabled = enabled
        self.intervalKm = intervalKm
        self.lastServiceOdometerKm = lastServiceOdometerKm
        self.remindBeforeKm = remindBeforeKm
    }
}

final class AppDataStore: ObservableObject {
    @Published var records: [AppMaintenanceRecord] = []
    @Published var reminderSettings: AppReminderSettings = AppReminderSettings(enabled: false, intervalKm: 0, lastServiceOdometerKm: 0, remindBeforeKm: 0)
    
    private let recordsFileName = "chain_guardian_records.json"
    private let settingsFileName = "chain_guardian_settings.json"
    
    private var recordsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(recordsFileName)
    }
    
    private var settingsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(settingsFileName)
    }
    
    var totalCost: Double {
        records.reduce(0) { $0 + $1.cost }
    }
    
    var averageCost: Double {
        records.isEmpty ? 0 : totalCost / Double(records.count)
    }
    
    var latestRecord: AppMaintenanceRecord? {
        records.max(by: { $0.date < $1.date })
    }
    
    var currentOdometer: Double {
        records.map(\.odometerKm).max() ?? 0
    }
    
    var totalRecords: Int {
        records.count
    }
    
    init() {
        load()
        #if DEBUG
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
        #endif
    }
    
    func addRecord(_ record: AppMaintenanceRecord) {
        records.append(record)
        sortRecords()
        saveRecords()
        updateReminderAfterServiceIfNeeded(record)
    }
    
    func updateRecord(_ record: AppMaintenanceRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
            sortRecords()
            saveRecords()
            updateReminderAfterServiceIfNeeded(record)
        }
    }
    
    func deleteRecord(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        sortRecords()
        saveRecords()
    }
    
    func deleteRecord(_ record: AppMaintenanceRecord) {
        records.removeAll { $0.id == record.id }
        sortRecords()
        saveRecords()
    }
    
    func saveSettings() {
        saveSettingsToDisk()
    }
    
    func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let data = try Data(contentsOf: recordsURL)
            records = try decoder.decode([AppMaintenanceRecord].self, from: data)
            sortRecords()
        } catch {
            records = []
        }
        
        do {
            let data = try Data(contentsOf: settingsURL)
            reminderSettings = try decoder.decode(AppReminderSettings.self, from: data)
        } catch {
            reminderSettings = AppReminderSettings(enabled: false, intervalKm: 0, lastServiceOdometerKm: 0, remindBeforeKm: 0)
        }
    }
    
    func sortRecords() {
        records.sort { $0.date > $1.date }
    }
    
    private func updateReminderAfterServiceIfNeeded(_ record: AppMaintenanceRecord) {
        if record.type == .lubrication || record.type == .cleaning {
            reminderSettings.lastServiceOdometerKm = max(reminderSettings.lastServiceOdometerKm, record.odometerKm)
            saveSettingsToDisk()
        }
    }
    
    private func saveRecords() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(records)
            try data.write(to: recordsURL)
        } catch {
            print("Failed to save records: \(error)")
        }
    }
    
    private func saveSettingsToDisk() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(reminderSettings)
            try data.write(to: settingsURL)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
}

#if DEBUG
enum DemoSeed {
    static func apply(into store: AppDataStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }
        
        let calendar = Calendar.current
        let today = Date()
        func daysAgo(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: -days, to: today) ?? today
        }
        
        let samples: [AppMaintenanceRecord] = [
            AppMaintenanceRecord(id: UUID(), date: daysAgo(142), type: .replacement, component: "Chain", notes: "Replaced stretched chain with Shimano CN-HG701", odometerKm: 1850, cost: 42.50, durationMinutes: 25),
            AppMaintenanceRecord(id: UUID(), date: daysAgo(118), type: .lubrication, component: "Chain", notes: "Applied wet lube after cleaning", odometerKm: 2140, cost: 3.80, durationMinutes: 15),
            AppMaintenanceRecord(id: UUID(), date: daysAgo(96), type: .cleaning, component: "Drivetrain", notes: "Degreased chain, cassette and chainrings", odometerKm: 2415, cost: 6.20, durationMinutes: 40),
            AppMaintenanceRecord(id: UUID(), date: daysAgo(81), type: .adjustment, component: "Rear Derailleur", notes: "Adjusted indexing after cable stretch", odometerKm: 2680, cost: 0, durationMinutes: 20),
            AppMaintenanceRecord(id: UUID(), date: daysAgo(62), type: .inspection, component: "Chain", notes: "Measured wear at 0.5%, still serviceable", odometerKm: 2905, cost: 0, durationMinutes: 10),
            AppMaintenanceRecord(id: UUID(), date: daysAgo(44), type: .replacement, component: "Brake Pads", notes: "Swapped front and rear pads with Shimano B05S", odometerKm: 3150, cost: 24.00, durationMinutes: 35),
            AppMaintenanceRecord(id: UUID(), date: daysAgo(31), type: .lubrication, component: "Chain", notes: "Dry lube after wet ride", odometerKm: 3420, cost: 2.90, durationMinutes: 12),
            AppMaintenanceRecord(id: UUID(), date: daysAgo(18), type: .cleaning, component: "Cassette", notes: "Deep cleaned cassette and jockey wheels", odometerKm: 3685, cost: 5.40, durationMinutes: 45),
            AppMaintenanceRecord(id: UUID(), date: daysAgo(9), type: .adjustment, component: "Front Derailleur", notes: "Trim adjustment for small ring rub", odometerKm: 3910, cost: 0, durationMinutes: 15),
            AppMaintenanceRecord(id: UUID(), date: daysAgo(1), type: .lubrication, component: "Chain", notes: "Quick top-up before weekend ride", odometerKm: 4155, cost: 1.75, durationMinutes: 8)
        ]
        
        store.records = samples
        store.sortRecords()
        store.reminderSettings = AppReminderSettings(
            enabled: true,
            intervalKm: 300,
            lastServiceOdometerKm: 4155,
            remindBeforeKm: 20
        )
        store.saveRecords()
        store.saveSettings()
    }
}
#endif