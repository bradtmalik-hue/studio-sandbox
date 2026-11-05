import Foundation
import Combine

struct LoopMoment: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var note: String = ""
    var date: Date = Date()
    var value: Double = 3.0
    var imageName: String? = nil
    var tags: [String] = []
}

final class LoopStore: ObservableObject {
    @Published var moments: [LoopMoment] = []
    
    private let fileURL: URL
    
    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documents.appendingPathComponent("loop-moments.json")
        load()
    }
    
    var sortedMoments: [LoopMoment] {
        moments.sorted { $0.date > $1.date }
    }
    
    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            moments = []
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            moments = try JSONDecoder().decode([LoopMoment].self, from: data)
        } catch {
            moments = []
        }
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(moments)
            try data.write(to: fileURL)
        } catch {
            // Save can fail silently; data remains in memory.
        }
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
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
        let store = LoopStore()
        guard store.moments.isEmpty else { return }
        
        let samples: [LoopMoment] = [
            LoopMoment(
                title: "Morning coffee on the balcony",
                note: "Quiet start before the day kicked in.",
                date: makeDate(daysAgo: 0, hour: 8),
                value: 4.5,
                imageName: "sample1",
                tags: ["morning", "coffee"]
            ),
            LoopMoment(
                title: "First run in the park",
                note: "Legs felt heavy but the air was fresh.",
                date: makeDate(daysAgo: 1, hour: 7),
                value: 3.8,
                imageName: "sample2",
                tags: ["fitness", "outdoor"]
            ),
            LoopMoment(
                title: "New book, quiet night",
                note: "Finally started the novel everyone recommended.",
                date: makeDate(daysAgo: 2, hour: 21),
                value: 4.2,
                imageName: nil,
                tags: ["reading", "evening"]
            ),
            LoopMoment(
                title: "Catching up with Sarah",
                note: "Long walk and even longer conversation.",
                date: makeDate(daysAgo: 3, hour: 18),
                value: 4.0,
                imageName: "sample3",
                tags: ["friends"]
            ),
            LoopMoment(
                title: "Rainy day work session",
                note: "Stayed in, made progress on the project.",
                date: makeDate(daysAgo: 4, hour: 14),
                value: 3.5,
                imageName: nil,
                tags: ["work", "focus"]
            ),
            LoopMoment(
                title: "Dinner with family",
                note: "Homemade pasta and lots of laughter.",
                date: makeDate(daysAgo: 5, hour: 19),
                value: 4.8,
                imageName: "sample4",
                tags: ["family", "food"]
            ),
            LoopMoment(
                title: "Late night walk",
                note: "The streets were empty and calm.",
                date: makeDate(daysAgo: 6, hour: 23),
                value: 3.0,
                imageName: "sample1",
                tags: ["night", "walk"]
            ),
            LoopMoment(
                title: "Weekend farmers market",
                note: "Picked up fresh berries and flowers.",
                date: makeDate(daysAgo: 7, hour: 10),
                value: 4.3,
                imageName: "sample2",
                tags: ["weekend", "market"]
            ),
            LoopMoment(
                title: "Sunset at the lake",
                note: "The sky turned orange and pink.",
                date: makeDate(daysAgo: 8, hour: 19),
                value: 4.7,
                imageName: "sample3",
                tags: ["nature", "sunset"]
            ),
            LoopMoment(
                title: "Trying a new recipe",
                note: "It looked messy but tasted great.",
                date: makeDate(daysAgo: 9, hour: 18),
                value: 3.9,
                imageName: "sample4",
                tags: ["cooking", "experiment"]
            )
        ]
        
        store.moments = samples
        store.save()
    }
    
    private static func makeDate(daysAgo: Int, hour: Int) -> Date {
        let now = Date()
        var components = Calendar.current.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = 0
        let base = Calendar.current.date(from: components) ?? now
        return Calendar.current.date(byAdding: .day, value: -daysAgo, to: base) ?? now
    }
}