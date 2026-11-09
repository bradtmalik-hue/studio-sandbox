import Foundation
import Combine

enum PlantCareCareType: String, Codable, CaseIterable, Identifiable {
    case watering
    case fertilizing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .watering: return "Watering"
        case .fertilizing: return "Fertilizing"
        }
    }
}

struct PlantCarePlant: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var location: String
    var wateringIntervalDays: Int
    var lastWateredDate: Date?
    var lastFertilizedDate: Date?
    var notes: String
}

struct PlantCareCareRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var plantID: UUID
    var type: PlantCareCareType
    var date: Date
    var amount: Double
    var note: String
}

final class PlantCareStore: ObservableObject {
    @Published var plants: [PlantCarePlant] = []
    @Published var careRecords: [PlantCareCareRecord] = []

    private let plantsFileName = "plants.json"
    private let recordsFileName = "care_records.json"

    init() {
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply()
        }
    }

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var plantsFileURL: URL {
        documentsDirectory.appendingPathComponent(plantsFileName)
    }

    private var recordsFileURL: URL {
        documentsDirectory.appendingPathComponent(recordsFileName)
    }

    func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let data = try? Data(contentsOf: plantsFileURL),
           let decoded = try? decoder.decode([PlantCarePlant].self, from: data) {
            plants = decoded
        }

        if let data = try? Data(contentsOf: recordsFileURL),
           let decoded = try? decoder.decode([PlantCareCareRecord].self, from: data) {
            careRecords = decoded
        }
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        if let data = try? encoder.encode(plants) {
            try? data.write(to: plantsFileURL)
        }

        if let data = try? encoder.encode(careRecords) {
            try? data.write(to: recordsFileURL)
        }
    }

    var todayWateringPlants: [PlantCarePlant] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        return plants
            .filter { plant in
                guard let lastWateredDate = plant.lastWateredDate else { return true }
                let startLast = calendar.startOfDay(for: lastWateredDate)
                let days = calendar.dateComponents([.day], from: startLast, to: startOfToday).day ?? 0
                return days >= plant.wateringIntervalDays
            }
            .sorted { ($0.lastWateredDate ?? .distantPast) < ($1.lastWateredDate ?? .distantPast) }
    }

    var plantCount: Int {
        plants.count
    }

    var recordCount: Int {
        careRecords.count
    }

    func addPlant(_ plant: PlantCarePlant) {
        plants.append(plant)
        save()
    }

    func updatePlant(_ plant: PlantCarePlant) {
        if let index = plants.firstIndex(where: { $0.id == plant.id }) {
            plants[index] = plant
            save()
        }
    }

    func deletePlant(_ plant: PlantCarePlant) {
        plants.removeAll { $0.id == plant.id }
        careRecords.removeAll { $0.plantID == plant.id }
        save()
    }

    func records(for plant: PlantCarePlant) -> [PlantCareCareRecord] {
        careRecords
            .filter { $0.plantID == plant.id }
            .sorted { $0.date > $1.date }
    }

    func addRecord(_ record: PlantCareCareRecord) {
        careRecords.append(record)

        if let index = plants.firstIndex(where: { $0.id == record.plantID }) {
            if record.type == .watering {
                plants[index].lastWateredDate = record.date
            } else if record.type == .fertilizing {
                plants[index].lastFertilizedDate = record.date
            }
        }

        save()
    }

    func deleteRecord(_ record: PlantCareCareRecord) {
        careRecords.removeAll { $0.id == record.id }
        save()
    }
}

enum DemoSeed {
    static func apply() {
        let store = PlantCareStore()
        apply(into: store)
    }

    static func apply(into store: PlantCareStore) {
        guard store.plants.isEmpty && store.careRecords.isEmpty else { return }

        let now = Date()
        let day: TimeInterval = 86400

        let plantList: [PlantCarePlant] = [
            PlantCarePlant(
                id: UUID(),
                name: "Monstera",
                location: "Living Room",
                wateringIntervalDays: 7,
                lastWateredDate: now.addingTimeInterval(-2 * day),
                lastFertilizedDate: now.addingTimeInterval(-30 * day),
                notes: "Bright indirect light, let topsoil dry between waterings."
            ),
            PlantCarePlant(
                id: UUID(),
                name: "Snake Plant",
                location: "Bedroom",
                wateringIntervalDays: 14,
                lastWateredDate: now.addingTimeInterval(-10 * day),
                lastFertilizedDate: now.addingTimeInterval(-45 * day),
                notes: "Tolerates low light and dry air."
            ),
            PlantCarePlant(
                id: UUID(),
                name: "Pothos",
                location: "Kitchen Shelf",
                wateringIntervalDays: 6,
                lastWateredDate: now.addingTimeInterval(-6 * day),
                lastFertilizedDate: now.addingTimeInterval(-20 * day),
                notes: "Trailing plant, water when leaves look slightly limp."
            ),
            PlantCarePlant(
                id: UUID(),
                name: "Peace Lily",
                location: "Bathroom",
                wateringIntervalDays: 5,
                lastWateredDate: now.addingTimeInterval(-1 * day),
                lastFertilizedDate: now.addingTimeInterval(-35 * day),
                notes: "Prefers high humidity and consistent moisture."
            ),
            PlantCarePlant(
                id: UUID(),
                name: "Fiddle Leaf Fig",
                location: "Office",
                wateringIntervalDays: 9,
                lastWateredDate: now.addingTimeInterval(-9 * day),
                lastFertilizedDate: now.addingTimeInterval(-50 * day),
                notes: "Needs bright filtered light and steady temperatures."
            ),
            PlantCarePlant(
                id: UUID(),
                name: "ZZ Plant",
                location: "Hallway",
                wateringIntervalDays: 21,
                lastWateredDate: now.addingTimeInterval(-21 * day),
                lastFertilizedDate: now.addingTimeInterval(-60 * day),
                notes: "Very drought tolerant, avoid overwatering."
            ),
            PlantCarePlant(
                id: UUID(),
                name: "Spider Plant",
                location: "Balcony",
                wateringIntervalDays: 7,
                lastWateredDate: now.addingTimeInterval(-4 * day),
                lastFertilizedDate: now.addingTimeInterval(-25 * day),
                notes: "Keep soil lightly moist during growing season."
            ),
            PlantCarePlant(
                id: UUID(),
                name: "Aloe Vera",
                location: "Kitchen Window",
                wateringIntervalDays: 18,
                lastWateredDate: now.addingTimeInterval(-18 * day),
                lastFertilizedDate: now.addingTimeInterval(-70 * day),
                notes: "Water deeply but infrequently, needs bright light."
            ),
            PlantCarePlant(
                id: UUID(),
                name: "Chinese Evergreen",
                location: "Dining Room",
                wateringIntervalDays: 8,
                lastWateredDate: now.addingTimeInterval(-3 * day),
                lastFertilizedDate: now.addingTimeInterval(-40 * day),
                notes: "Low to medium indirect light, allow soil to dry slightly."
            ),
            PlantCarePlant(
                id: UUID(),
                name: "Rubber Plant",
                location: "Bedroom Corner",
                wateringIntervalDays: 10,
                lastWateredDate: now.addingTimeInterval(-8 * day),
                lastFertilizedDate: now.addingTimeInterval(-55 * day),
                notes: "Wipe leaves monthly to keep pores clean."
            )
        ]

        store.plants = plantList

        let records: [PlantCareCareRecord] = [
            PlantCareCareRecord(
                id: UUID(),
                plantID: plantList[0].id,
                type: .watering,
                date: now.addingTimeInterval(-2 * day),
                amount: 300,
                note: "Watered thoroughly until runoff."
            ),
            PlantCareCareRecord(
                id: UUID(),
                plantID: plantList[0].id,
                type: .fertilizing,
                date: now.addingTimeInterval(-30 * day),
                amount: 5,
                note: "Half-strength liquid fertilizer."
            ),
            PlantCareCareRecord(
                id: UUID(),
                plantID: plantList[1].id,
                type: .watering,
                date: now.addingTimeInterval(-10 * day),
                amount: 180,
                note: "Watered moderately."
            ),
            PlantCareCareRecord(
                id: UUID(),
                plantID: plantList[2].id,
                type: .watering,
                date: now.addingTimeInterval(-6 * day),
                amount: 250,
                note: "Top inch of soil was dry."
            ),
            PlantCareCareRecord(
                id: UUID(),
                plantID: plantList[3].id,
                type: .watering,
                date: now.addingTimeInterval(-1 * day),
                amount: 220,
                note: "Kept soil damp but not soggy."
            ),
            PlantCareCareRecord(
                id: UUID(),
                plantID: plantList[3].id,
                type: .fertilizing,
                date: now.addingTimeInterval(-35 * day),
                amount: 4,
                note: "Orchid fertilizer diluted."
            ),
            PlantCareCareRecord(
                id: UUID(),
                plantID: plantList[4].id,
                type: .watering,
                date: now.addingTimeInterval(-9 * day),
                amount: 400,
                note: "Watered deeply once top two inches were dry."
            ),
            PlantCareCareRecord(
                id: UUID(),
                plantID: plantList[5].id,
                type: .watering,
                date: now.addingTimeInterval(-21 * day),
                amount: 150,
                note: "Dry soil before watering."
            ),
            PlantCareCareRecord(
                id: UUID(),
                plantID: plantList[6].id,
                type: .watering,
                date: now.addingTimeInterval(-4 * day),
                amount: 200,
                note: "Balcony plant, checked soil moisture first."
            ),
            PlantCareCareRecord(
                id: UUID(),
                plantID: plantList[7].id,
                type: .watering,
                date: now.addingTimeInterval(-18 * day),
                amount: 160,
                note: "Last watered three weeks ago."
            ),
            PlantCareCareRecord(
                id: UUID(),
                plantID: plantList[8].id,
                type: .watering,
                date: now.addingTimeInterval(-3 * day),
                amount: 230,
                note: "Watered until damp at two inches."
            ),
            PlantCareCareRecord(
                id: UUID(),
                plantID: plantList[9].id,
                type: .watering,
                date: now.addingTimeInterval(-8 * day),
                amount: 320,
                note: "Checked first two inches before watering."
            )
        ]

        store.careRecords = records
        store.save()
    }
}