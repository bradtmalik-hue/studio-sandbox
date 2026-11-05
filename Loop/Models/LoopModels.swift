import Foundation
import Combine

struct LoopMoment: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var note: String
    var date: Date
    var mood: Double
    var imageName: String?
    var tags: [String]

    init(id: UUID = UUID(), title: String, note: String, date: Date = Date(), mood: Double = 0, imageName: String? = nil, tags: [String] = []) {
        self.id = id
        self.title = title
        self.note = note
        self.date = date
        self.mood = mood
        self.imageName = imageName
        self.tags = tags
    }
}

class LoopStore: ObservableObject {
    @Published var moments: [LoopMoment] = []

    private let fileURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent("LoopMoments.json")
        load()
    }

    func add(_ moment: LoopMoment) {
        moments.append(moment)
        save()
    }

    func update(_ moment: LoopMoment) {
        guard let index = moments.firstIndex(where: { $0.id == moment.id }) else { return }
        moments[index] = moment
        save()
    }

    func delete(_ moment: LoopMoment) {
        moments.removeAll { $0.id == moment.id }
        save()
    }

    func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            moments = try decoder.decode([LoopMoment].self, from: data)
        } catch {
            moments = []
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(moments)
            try data.write(to: fileURL)
        } catch {
            // Ignore write failures for demo simplicity; in production might handle.
        }
    }

    func seedDemoData() {
        let calendar = Calendar.current
        let now = Date()
        let demoMoments: [LoopMoment] = [
            LoopMoment(
                title: "Morning coffee by the window",
                note: "The light was soft and the coffee strong. Felt grateful for slow starts.",
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                mood: 7.5,
                imageName: "sample1",
                tags: ["morning", "gratitude"]
            ),
            LoopMoment(
                title: "Afternoon run along the river",
                note: "Legs were heavy but the breeze kept me going. 5k done.",
                date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                mood: 8.0,
                imageName: "sample2",
                tags: ["fitness", "outdoors"]
            ),
            LoopMoment(
                title: "Tried a new recipe",
                note: "Spicy noodles turned out better than expected. Need more chili next time.",
                date: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                mood: 6.5,
                imageName: nil,
                tags: ["cooking", "experiment"]
            ),
            LoopMoment(
                title: "Late night coding session",
                note: "Finally cracked the data model. Small wins matter.",
                date: calendar.date(byAdding: .day, value: -4, to: now) ?? now,
                mood: 5.0,
                imageName: "sample3",
                tags: ["work", "focus"]
            ),
            LoopMoment(
                title: "Bookstore wander",
                note: "Found a collection of short stories that reminded me why I love reading.",
                date: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
                mood: 9.0,
                imageName: "sample4",
                tags: ["books", "inspiration"]
            ),
            LoopMoment(
                title: "Rainy Sunday reset",
                note: "Cleaned the desk, journaled, and made tea. Reset for the week.",
                date: calendar.date(byAdding: .day, value: -6, to: now) ?? now,
                mood: 7.0,
                imageName: nil,
                tags: ["self-care", "home"]
            ),
            LoopMoment(
                title: "Catch-up call with an old friend",
                note: "We laughed about old times and planned a trip. Connection matters.",
                date: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
                mood: 8.5,
                imageName: "sample1",
                tags: ["friends", "memories"]
            ),
            LoopMoment(
                title: "Photography walk at sunset",
                note: "Golden hour was unreal. The sky looked painted.",
                date: calendar.date(byAdding: .day, value: -8, to: now) ?? now,
                mood: 9.5,
                imageName: "sample2",
                tags: ["photography", "nature"]
            ),
            LoopMoment(
                title: "Baking banana bread",
                note: "Kitchen smelled amazing. Shared half with neighbor.",
                date: calendar.date(byAdding: .day, value: -9, to: now) ?? now,
                mood: 7.8,
                imageName: "sample3",
                tags: ["baking", "sharing"]
            ),
            LoopMoment(
                title: "Evening stretch and podcast",
                note: "Slow movement and a good story about design. Perfect wind-down.",
                date: calendar.date(byAdding: .day, value: -10, to: now) ?? now,
                mood: 6.8,
                imageName: nil,
                tags: ["wellness", "podcast"]
            )
        ]
        moments = demoMoments
    }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
        let store = LoopStore()
        if store.moments.isEmpty {
            store.seedDemoData()
            store.save()
        }
    }
}