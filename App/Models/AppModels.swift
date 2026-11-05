import Foundation
import Combine

struct AppMedicine: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var storageSpot: String
    var expiryDate: Date
    var reminderDays: Int
    var notes: String

    init(
        id: UUID = UUID(),
        name: String = "",
        storageSpot: String = "",
        expiryDate: Date = Date(),
        reminderDays: Int = 14,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.storageSpot = storageSpot
        self.expiryDate = expiryDate
        self.reminderDays = reminderDays
        self.notes = notes
    }

    var daysUntilExpiry: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfExpiry = calendar.startOfDay(for: expiryDate)
        return calendar.dateComponents([.day], from: startOfToday, to: startOfExpiry).day ?? 0
    }

    var isExpired: Bool {
        daysUntilExpiry < 0
    }

    var isExpiringSoon: Bool {
        daysUntilExpiry >= 0 && daysUntilExpiry <= reminderDays
    }
}

struct AppReminderSettings: Codable, Equatable {
    var defaultReminderDays: Int
    var expiryRemindersEnabled: Bool

    init(defaultReminderDays: Int = 14, expiryRemindersEnabled: Bool = true) {
        self.defaultReminderDays = defaultReminderDays
        self.expiryRemindersEnabled = expiryRemindersEnabled
    }
}

final class AppStore: ObservableObject {
    @Published var medicines: [AppMedicine] = []
    @Published var reminderSettings: AppReminderSettings = AppReminderSettings()

    private let medicinesFileName = "medicines.json"
    private let settingsFileName = "reminderSettings.json"

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var medicinesFileURL: URL {
        documentsDirectory.appendingPathComponent(medicinesFileName)
    }

    private var settingsFileURL: URL {
        documentsDirectory.appendingPathComponent(settingsFileName)
    }

    init() {
        loadMedicines()
        loadReminderSettings()
    }

    func addMedicine(_ medicine: AppMedicine) {
        medicines.append(medicine)
        saveMedicines()
    }

    func updateMedicine(_ medicine: AppMedicine) {
        guard let index = medicines.firstIndex(where: { $0.id == medicine.id }) else {
            return
        }
        medicines[index] = medicine
        saveMedicines()
    }

    func deleteMedicine(_ medicine: AppMedicine) {
        medicines.removeAll { $0.id == medicine.id }
        saveMedicines()
    }

    func deleteMedicines(at offsets: IndexSet) {
        medicines.remove(atOffsets: offsets)
        saveMedicines()
    }

    func updateReminderSettings(_ settings: AppReminderSettings) {
        reminderSettings = settings
        saveReminderSettings()
    }

    func setDefaultReminderDays(_ days: Int) {
        reminderSettings.defaultReminderDays = days
        saveReminderSettings()
    }

    func setExpiryRemindersEnabled(_ enabled: Bool) {
        reminderSettings.expiryRemindersEnabled = enabled
        saveReminderSettings()
    }

    private func loadMedicines() {
        guard FileManager.default.fileExists(atPath: medicinesFileURL.path) else {
            return
        }
        do {
            let data = try Data(contentsOf: medicinesFileURL)
            medicines = try JSONDecoder().decode([AppMedicine].self, from: data)
        } catch {
            medicines = []
        }
    }

    private func saveMedicines() {
        do {
            let data = try JSONEncoder().encode(medicines)
            try data.write(to: medicinesFileURL)
        } catch {
            // 无法保存时忽略，避免崩溃
        }
    }

    private func loadReminderSettings() {
        guard FileManager.default.fileExists(atPath: settingsFileURL.path) else {
            return
        }
        do {
            let data = try Data(contentsOf: settingsFileURL)
            reminderSettings = try JSONDecoder().decode(AppReminderSettings.self, from: data)
        } catch {
            reminderSettings = AppReminderSettings()
        }
    }

    private func saveReminderSettings() {
        do {
            let data = try JSONEncoder().encode(reminderSettings)
            try data.write(to: settingsFileURL)
        } catch {
            // 无法保存时忽略，避免崩溃
        }
    }
}