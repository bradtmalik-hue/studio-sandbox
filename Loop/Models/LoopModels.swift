import Foundation
import Combine

struct LoopMoment: Identifiable, Codable {
    var id = UUID()
    var author: String
    var imageName: String?
    var caption: String
    var date: Date
    var likedByMe: Bool
    var likeCount: Int
    var commentCount: Int
}

struct LoopMessage: Identifiable, Codable {
    var id = UUID()
    var author: String
    var text: String
    var date: Date
}

struct LoopMember: Identifiable, Codable {
    var id = UUID()
    var name: String
    var avatarName: String?
}

final class LoopStore: ObservableObject {
    static let fileURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("loop_store.json")
    }()

    @Published var moments: [LoopMoment] = []
    @Published var messages: [LoopMessage] = []
    @Published var members: [LoopMember] = []

    init() {
        load()
    }

    func addMoment(author: String, imageName: String?, caption: String) {
        let moment = LoopMoment(
            author: author,
            imageName: imageName,
            caption: caption,
            date: Date(),
            likedByMe: false,
            likeCount: 0,
            commentCount: 0
        )
        moments.insert(moment, at: 0)
        save()
    }

    func toggleLike(momentID: UUID) {
        guard let index = moments.firstIndex(where: { $0.id == momentID }) else { return }
        moments[index].likedByMe.toggle()
        moments[index].likeCount += moments[index].likedByMe ? 1 : -1
        save()
    }

    func addMessage(author: String, text: String) {
        let message = LoopMessage(author: author, text: text, date: Date())
        messages.append(message)
        save()
    }

    func addMember(name: String, avatarName: String? = nil) {
        let member = LoopMember(name: name, avatarName: avatarName)
        members.append(member)
        save()
    }

    func save() {
        let container = LoopStoreData(moments: moments, messages: messages, members: members)
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(container)
            try data.write(to: Self.fileURL)
        } catch {
            // Local demo write failure can be safely ignored.
        }
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: Self.fileURL),
              let container = try? decoder.decode(LoopStoreData.self, from: data) else {
            return
        }
        moments = container.moments
        messages = container.messages
        members = container.members
    }

    private struct LoopStoreData: Codable {
        var moments: [LoopMoment]
        var messages: [LoopMessage]
        var members: [LoopMember]
    }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }

        let store = LoopStore()
        guard store.moments.isEmpty, store.messages.isEmpty, store.members.isEmpty else { return }

        let calendar = Calendar.current
        func date(daysAgo: Int, hour: Int, minute: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }

        let moments: [LoopMoment] = [
            LoopMoment(
                author: "Maya",
                imageName: "sample1",
                caption: "Golden hour at the cabin",
                date: date(daysAgo: 0, hour: 18, minute: 20),
                likedByMe: true,
                likeCount: 24,
                commentCount: 5
            ),
            LoopMoment(
                author: "Jon",
                imageName: "sample2",
                caption: "Sunday farmers market haul",
                date: date(daysAgo: 1, hour: 10, minute: 15),
                likedByMe: false,
                likeCount: 18,
                commentCount: 4
            ),
            LoopMoment(
                author: "Priya",
                imageName: "sample3",
                caption: "Finally tried that tiny ramen spot",
                date: date(daysAgo: 1, hour: 19, minute: 45),
                likedByMe: true,
                likeCount: 31,
                commentCount: 7
            ),
            LoopMoment(
                author: "Maya",
                imageName: "sample4",
                caption: "Morning light from the balcony",
                date: date(daysAgo: 2, hour: 8, minute: 5),
                likedByMe: false,
                likeCount: 12,
                commentCount: 2
            ),
            LoopMoment(
                author: "Alex",
                imageName: "sample1",
                caption: "Desk setup week three",
                date: date(daysAgo: 3, hour: 14, minute: 30),
                likedByMe: true,
                likeCount: 27,
                commentCount: 6
            ),
            LoopMoment(
                author: "Jon",
                imageName: "sample2",
                caption: "Trail run before the rain",
                date: date(daysAgo: 4, hour: 7, minute: 50),
                likedByMe: false,
                likeCount: 19,
                commentCount: 3
            ),
            LoopMoment(
                author: "Priya",
                imageName: "sample3",
                caption: "Homemade pasta night",
                date: date(daysAgo: 5, hour: 20, minute: 10),
                likedByMe: true,
                likeCount: 22,
                commentCount: 5
            ),
            LoopMoment(
                author: "Alex",
                imageName: "sample4",
                caption: "New plant corner is coming together",
                date: date(daysAgo: 6, hour: 16, minute: 45),
                likedByMe: false,
                likeCount: 16,
                commentCount: 4
            ),
            LoopMoment(
                author: "Maya",
                imageName: "sample1",
                caption: "Weekend road trip starts now",
                date: date(daysAgo: 7, hour: 9, minute: 0),
                likedByMe: true,
                likeCount: 35,
                commentCount: 8
            ),
            LoopMoment(
                author: "Jon",
                imageName: "sample2",
                caption: "Sunrise from the ferry",
                date: date(daysAgo: 8, hour: 6, minute: 25),
                likedByMe: false,
                likeCount: 28,
                commentCount: 6
            )
        ]

        let messages: [LoopMessage] = [
            LoopMessage(
                author: "Maya",
                text: "That ramen looks unreal. Send me the spot?",
                date: date(daysAgo: 0, hour: 19, minute: 48)
            ),
            LoopMessage(
                author: "Priya",
                text: "Hidden on 12th Ave. Tiny but absolutely worth it.",
                date: date(daysAgo: 0, hour: 19, minute: 52)
            ),
            LoopMessage(
                author: "Jon",
                text: "Count me in for the next loop hangout",
                date: date(daysAgo: 1, hour: 12, minute: 10)
            ),
            LoopMessage(
                author: "Alex",
                text: "That balcony light is perfect for reading",
                date: date(daysAgo: 2, hour: 8, minute: 12)
            ),
            LoopMessage(
                author: "Maya",
                text: "Bringing the film camera this weekend 🎞",
                date: date(daysAgo: 3, hour: 21, minute: 5)
            ),
            LoopMessage(
                author: "Priya",
                text: "Plant corner is thriving. Pics soon.",
                date: date(daysAgo: 4, hour: 9, minute: 30)
            ),
            LoopMessage(
                author: "Jon",
                text: "Trail was muddy but the view was worth it",
                date: date(daysAgo: 4, hour: 8, minute: 20)
            ),
            LoopMessage(
                author: "Alex",
                text: "Road trip playlist is ready. Don't worry, no skips.",
                date: date(daysAgo: 7, hour: 8, minute: 45)
            )
        ]

        let members: [LoopMember] = [
            LoopMember(name: "Maya", avatarName: "sample1"),
            LoopMember(name: "Jon", avatarName: "sample2"),
            LoopMember(name: "Priya", avatarName: "sample3"),
            LoopMember(name: "Alex", avatarName: "sample4"),
            LoopMember(name: "Sam", avatarName: "sample1"),
            LoopMember(name: "Nora", avatarName: "sample2")
        ]

        store.moments = moments
        store.messages = messages
        store.members = members
        store.save()
    }
}