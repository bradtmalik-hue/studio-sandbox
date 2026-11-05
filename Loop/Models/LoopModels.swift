import Foundation
import Combine

struct LoopMoment: Identifiable, Codable, Equatable {
    var id: UUID
    var text: String
    var imageName: String?
    var createdAt: Date

    init(id: UUID = UUID(), text: String, imageName: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.imageName = imageName
        self.createdAt = createdAt
    }
}

struct LoopMessage: Identifiable, Codable, Equatable {
    var id: UUID
    var text: String
    var sentAt: Date
    var isFromMe: Bool

    init(id: UUID = UUID(), text: String, sentAt: Date = Date(), isFromMe: Bool) {
        self.id = id
        self.text = text
        self.sentAt = sentAt
        self.isFromMe = isFromMe
    }
}

struct LoopConversation: Identifiable, Codable, Equatable {
    var id: UUID
    var momentID: UUID
    var participantName: String
    var createdAt: Date
    var messages: [LoopMessage]

    init(
        id: UUID = UUID(),
        momentID: UUID,
        participantName: String,
        createdAt: Date = Date(),
        messages: [LoopMessage] = []
    ) {
        self.id = id
        self.momentID = momentID
        self.participantName = participantName
        self.createdAt = createdAt
        self.messages = messages
    }
}

struct LoopData: Codable {
    var moments: [LoopMoment]
    var conversations: [LoopConversation]
}

final class LoopStore: ObservableObject {
    @Published var moments: [LoopMoment] = []
    @Published var conversations: [LoopConversation] = []

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsDirectory.appendingPathComponent("loop-data.json")

        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601

        if FileManager.default.fileExists(atPath: fileURL.path) {
            load()
        } else {
            seedInitialData()
            save()
        }
    }

    @discardableResult
    func addMoment(text: String, imageName: String? = nil) -> LoopMoment {
        let moment = LoopMoment(text: text, imageName: imageName)
        moments.insert(moment, at: 0)
        save()
        return moment
    }

    func deleteMoment(_ moment: LoopMoment) {
        moments.removeAll { $0.id == moment.id }
        conversations.removeAll { $0.momentID == moment.id }
        save()
    }

    @discardableResult
    func addConversation(momentID: UUID, participantName: String) -> LoopConversation? {
        guard moments.contains(where: { $0.id == momentID }) else { return nil }
        let conversation = LoopConversation(momentID: momentID, participantName: participantName)
        conversations.insert(conversation, at: 0)
        save()
        return conversation
    }

    func deleteConversation(_ conversation: LoopConversation) {
        conversations.removeAll { $0.id == conversation.id }
        save()
    }

    func sendMessage(in conversationID: UUID, text: String, isFromMe: Bool) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        let message = LoopMessage(text: trimmedText, isFromMe: isFromMe)
        if let index = conversations.firstIndex(where: { $0.id == conversationID }) {
            conversations[index].messages.append(message)
            save()
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try decoder.decode(LoopData.self, from: data)
            self.moments = decoded.moments.sorted { $0.createdAt > $1.createdAt }
            self.conversations = decoded.conversations.sorted { $0.createdAt > $1.createdAt }
        } catch {
            self.moments = []
            self.conversations = []
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(LoopData(moments: moments, conversations: conversations))
            try data.write(to: fileURL)
        } catch {
            print("Loop save error: \(error.localizedDescription)")
        }
    }

    private func seedInitialData() {
        let now = Date()
        let sampleMoments = [
            LoopMoment(
                text: "Morning light through the kitchen window. Coffee always tastes better like this.",
                imageName: "sample1",
                createdAt: now.addingTimeInterval(-3600)
            ),
            LoopMoment(
                text: "Took the long way home and found this quiet street full of golden leaves.",
                imageName: "sample2",
                createdAt: now.addingTimeInterval(-7200)
            ),
            LoopMoment(
                text: "First batch of sourdough this year. The crust crackled for a full minute.",
                imageName: "sample3",
                createdAt: now.addingTimeInterval(-10800)
            ),
            LoopMoment(
                text: "Sunday reset: fresh sheets, open windows, nothing urgent.",
                imageName: "sample4",
                createdAt: now.addingTimeInterval(-14400)
            )
        ]

        self.moments = sampleMoments

        if let firstMoment = sampleMoments.first {
            let conversation = LoopConversation(
                momentID: firstMoment.id,
                participantName: "Alex",
                createdAt: now.addingTimeInterval(-1800),
                messages: [
                    LoopMessage(text: "That light is unreal. Was it as warm as it looks?", sentAt: now.addingTimeInterval(-1700), isFromMe: false),
                    LoopMessage(text: "Even warmer. Stayed there until the coffee got cold.", sentAt: now.addingTimeInterval(-1500), isFromMe: true)
                ]
            )
            self.conversations = [conversation]
        }
    }
}