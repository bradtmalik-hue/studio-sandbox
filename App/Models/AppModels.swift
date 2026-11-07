import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
}

struct Post: Identifiable, Codable {
    let id: UUID
    var author: String
    var content: String
}

struct AppModel {
    static let sampleUsers: [User] = []
    static let samplePosts: [Post] = []
}

struct DataProvider {
    static var firstUser: User? {
        guard !AppModel.sampleUsers.isEmpty else { return nil }
        return AppModel.sampleUsers[0]
    }
}
