import Foundation
import Combine

struct LoopMoment: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var title: String
    var note: String
    var date: Date
    var imageName: String
    var viewedCount: Int
    var isShared: Bool
    var favorite: Bool
    var mood: String
}

final class LoopStore: ObservableObject {
    @Published var moments: [LoopMoment] = []
    
    private let fileName = "loopMoments.json"
    
    private var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(fileName)
    }
    
    init() {
        load()
    }
    
    func load() {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([LoopMoment].self, from: data) {
            moments = decoded
        }
    }
    
    func save() {
        guard let url = fileURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(moments)
            try data.write(to: url)
        } catch {
            // Write failed; keep in-memory data.
        }
    }
    
    func add(_ moment: LoopMoment) {
        moments.append(moment)
        save()
    }
    
    func update(_ moment: LoopMoment) {
        if let index = moments.firstIndex(where: { $0.id == moment.id }) {
            moments[index] = moment
            save()
        }
    }
    
    func delete(_ moment: LoopMoment) {
        moments.removeAll { $0.id == moment.id }
        save()
    }
    
    func delete(at offsets: IndexSet) {
        moments.remove(atOffsets: offsets)
        save()
    }
    
    func markViewed(_ moment: LoopMoment) {
        guard let index = moments.firstIndex(where: { $0.id == moment.id }) else { return }
        moments[index].viewedCount += 1
        save()
    }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
        let store = LoopStore()
        guard store.moments.isEmpty else { return }
        
        let calendar = Calendar.current
        let now = Date()
        func daysAgo(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: -days, to: now) ?? now
        }
        
        let seeds: [LoopMoment] = [
            LoopMoment(
                title: "Golden Hour at the Park",
                note: "That warm light made everything feel like a film. We should do this every week.",
                date: daysAgo(2),
                imageName: "sample1",
                viewedCount: 14,
                isShared: true,
                favorite: true,
                mood: "Warm"
            ),
            LoopMoment(
                title: "Coffee Run Before Work",
                note: "The little detour that turned into a 40-minute conversation.",
                date: daysAgo(5),
                imageName: "sample2",
                viewedCount: 9,
                isShared: true,
                favorite: false,
                mood: "Cozy"
            ),
            LoopMoment(
                title: "Sunday Morning Farmers Market",
                note: "Fresh berries, good bread, and the best chai we've had all month.",
                date: daysAgo(8),
                imageName: "sample3",
                viewedCount: 21,
                isShared: true,
                favorite: true,
                mood: "Fresh"
            ),
            LoopMoment(
                title: "Hike Near the Lake",
                note: "The view from the top was worth every switchback. My legs still remember.",
                date: daysAgo(12),
                imageName: "sample4",
                viewedCount: 18,
                isShared: true,
                favorite: true,
                mood: "Adventurous"
            ),
            LoopMoment(
                title: "Board Game Night",
                note: "We laughed so hard we forgot whose turn it was. Rematch soon?",
                date: daysAgo(15),
                imageName: "sample1",
                viewedCount: 11,
                isShared: true,
                favorite: false,
                mood: "Playful"
            ),
            LoopMoment(
                title: "Rainy Window Seat",
                note: "A quiet afternoon with tea and a book. You looked so at peace.",
                date: daysAgo(19),
                imageName: "sample2",
                viewedCount: 7,
                isShared: false,
                favorite: true,
                mood: "Calm"
            ),
            LoopMoment(
                title: "Impromptu Picnic",
                note: "We grabbed whatever was in the fridge and it somehow became a feast.",
                date: daysAgo(23),
                imageName: "sample3",
                viewedCount: 16,
                isShared: true,
                favorite: true,
                mood: "Spontaneous"
            ),
            LoopMoment(
                title: "Late Night Drive",
                note: "Windows down, playlist on shuffle, no destination. Just the loop.",
                date: daysAgo(27),
                imageName: "sample4",
                viewedCount: 13,
                isShared: true,
                favorite: false,
                mood: "Free"
            ),
            LoopMoment(
                title: "Homemade Pizza Night",
                note: "Flour everywhere, but the result was better than delivery.",
                date: daysAgo(31),
                imageName: "sample1",
                viewedCount: 10,
                isShared: true,
                favorite: true,
                mood: "Satisfying"
            ),
            LoopMoment(
                title: "Beach Afternoon",
                note: "The water was cold, the sun was warm, and the day felt endless.",
                date: daysAgo(36),
                imageName: "sample2",
                viewedCount: 22,
                isShared: true,
                favorite: true,
                mood: "Bright"
            )
        ]
        
        store.moments = seeds
        store.save()
    }
}