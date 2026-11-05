import Foundation

enum AppModels {
    struct Message: Identifiable, Codable, Equatable {
        let id: UUID
        var role: Role
        var content: String
        var createdAt: Date

        init(id: UUID = UUID(), role: Role, content: String, createdAt: Date = Date()) {
            self.id = id
            self.role = role
            self.content = content
            self.createdAt = createdAt
        }
    }

    enum Role: String, Codable, CaseIterable {
        case system
        case user
        case assistant
    }

    struct Conversation: Identifiable, Codable, Equatable {
        let id: UUID
        var title: String
        var messages: [Message]
        var createdAt: Date
        var updatedAt: Date

        init(
            id: UUID = UUID(),
            title: String,
            messages: [Message] = [],
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.title = title
            self.messages = messages
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }
}