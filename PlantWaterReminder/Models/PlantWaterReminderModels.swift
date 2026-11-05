import Foundation
import Combine

struct PlantWaterReminderPlant: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var species: String
    var location: String
    var wateringIntervalDays: Int
    var lastWateredDate: Date?
    var notes: String
    var iconName: String

    init(
        id: UUID = UUID(),
        name: String,
        species: String = "",
        location: String = "",
        wateringIntervalDays: Int,
        lastWateredDate: Date? = nil,
        notes: String = "",
        iconName: String = "leaf"
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.location = location
        self.wateringIntervalDays = max(1, wateringIntervalDays)
        self.lastWateredDate = lastWateredDate
        self.notes = notes
        self.iconName = iconName
    }

    var nextWateringDate: Date? {
        guard let lastWateredDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: wateringIntervalDays, to: lastWateredDate)
    }

    var isDue: Bool {
        guard let nextWateringDate else { return true }
        return nextWateringDate <= Date()
    }

    var daysUntilWatering: Int {
        guard let nextWateringDate else { return 0 }
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let startOfNext = Calendar.current.startOfDay(for: nextWateringDate)
        return Calendar.current.dateComponents([.day], from: startOfToday, to: startOfNext).day ?? 0
    }

    var daysOverdue: Int {
        guard isDue else { return 0 }
        guard let nextWateringDate else { return 1 }
        let startOfNext = Calendar.current.startOfDay(for: nextWateringDate)
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return Calendar.current.dateComponents([.day], from: startOfNext, to: startOfToday).day ?? 1
    }
}

@MainActor
final class PlantWaterReminderStore: ObservableObject {
    @Published var plants: [PlantWaterReminderPlant] = []

    init() {
        load()
    }

    var duePlants: [PlantWaterReminderPlant] {
        plants.filter { $0.isDue }
            .sorted {
                ($0.nextWateringDate ?? .distantPast) < ($1.nextWateringDate ?? .distantPast)
            }
    }

    var healthyPlants: [PlantWaterReminderPlant] {
        plants.filter { !$0.isDue }
    }

    var overdueCount: Int {
        duePlants.count
    }

    func addPlant(
        name: String,
        species: String = "",
        location: String = "",
        wateringIntervalDays: Int,
        notes: String = "",
        iconName: String = "leaf"
    ) {
        let plant = PlantWaterReminderPlant(
            name: name,
            species: species,
            location: location,
            wateringIntervalDays: wateringIntervalDays,
            notes: notes,
            iconName: iconName
        )
        plants.append(plant)
        save()
    }

    func updatePlant(_ plant: PlantWaterReminderPlant) {
        guard let index = plants.firstIndex(where: { $0.id == plant.id }) else { return }
        plants[index] = plant
        save()
    }

    func deletePlant(_ plant: PlantWaterReminderPlant) {
        plants.removeAll { $0.id == plant.id }
        save()
    }

    func deletePlants(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            plants.remove(at: index)
        }
        save()
    }

    func waterPlant(_ plant: PlantWaterReminderPlant) {
        guard let index = plants.firstIndex(where: { $0.id == plant.id }) else { return }
        plants[index].lastWateredDate = Date()
        save()
    }

    func plant(with id: UUID) -> PlantWaterReminderPlant? {
        plants.first { $0.id == id }
    }

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("plantWaterReminder.json")
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private func load() {
        let url = Self.fileURL
        guard let data = try? Data(contentsOf: url) else {
            plants = []
            return
        }

        do {
            plants = try Self.decoder.decode([PlantWaterReminderPlant].self, from: data)
        } catch {
            plants = []
        }
    }

    private func save() {
        do {
            let data = try Self.encoder.encode(plants)
            try data.write(to: Self.fileURL)
        } catch {
            // Local persistence errors should not interrupt the UI.
        }
    }
}

extension PlantWaterReminderStore {
    static var preview: PlantWaterReminderStore {
        let store = PlantWaterReminderStore()
        store.plants = [
            PlantWaterReminderPlant(
                name: "Monstera",
                species: "Monstera deliciosa",
                location: "Living Room",
                wateringIntervalDays: 7,
                lastWateredDate: Calendar.current.date(byAdding: .day, value: -8, to: Date()) ?? Date(),
                notes: "Thrives in bright indirect light",
                iconName: "leaf"
            ),
            PlantWaterReminderPlant(
                name: "Snake Plant",
                species: "Dracaena trifasciata",
                location: "Bedroom",
                wateringIntervalDays: 14,
                lastWateredDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
                notes: "Water sparingly",
                iconName: "leaf.fill"
            ),
            PlantWaterReminderPlant(
                name: "Pothos",
                species: "Epipremnum aureum",
                location: "Office",
                wateringIntervalDays: 5,
                lastWateredDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                notes: "Likes to dry out between watering",
                iconName: "camera.macro"
            )
        ]
        return store
    }
}