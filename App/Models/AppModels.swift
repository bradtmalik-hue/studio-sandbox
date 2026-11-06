import Foundation
import Combine

struct AppMedicine: Identifiable, Codable {
    let id: UUID
    var name: String
    var location: String
    var expiryDate: Date
    var createdAt: Date
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        location: String,
        expiryDate: Date,
        createdAt: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.expiryDate = expiryDate
        self.createdAt = createdAt
        self.notes = notes
    }

    var isExpired: Bool {
        expiryDate < Date()
    }

    var isExpiringSoon: Bool {
        let calendar = Calendar.current
        guard let soon = calendar.date(byAdding: .day, value: 30, to: Date()) else {
            return false
        }
        return expiryDate < soon && !isExpired
    }
}

class AppStore: ObservableObject {
    @Published var medicines: [AppMedicine] = []

    init() {
        medicines = []
    }

    var totalCount: Int {
        medicines.count
    }

    var expiredCount: Int {
        medicines.filter { $0.isExpired }.count
    }

    var expiringCount: Int {
        medicines.filter { $0.isExpiringSoon }.count
    }

    var uniqueLocations: [String] {
        Array(Set(medicines.map { $0.location })).sorted()
    }

    var nearestExpiry: AppMedicine? {
        medicines.min { $0.expiryDate < $1.expiryDate }
    }

    var recentlyAdded: [AppMedicine] {
        medicines.sorted { $0.createdAt > $1.createdAt }
    }

    func addMedicine(_ medicine: AppMedicine) {
        medicines.append(medicine)
    }

    func updateMedicine(_ medicine: AppMedicine) {
        guard let index = medicines.firstIndex(where: { $0.id == medicine.id }) else {
            return
        }
        medicines[index] = medicine
    }

    func deleteMedicine(_ medicine: AppMedicine) {
        medicines.removeAll { $0.id == medicine.id }
    }

    func medicine(withId id: UUID) -> AppMedicine? {
        medicines.first { $0.id == id }
    }
}