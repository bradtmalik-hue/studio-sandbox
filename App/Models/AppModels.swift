import Foundation

struct Item: Identifiable, Codable {
    var id = UUID()
    var name: String = ""
    var detail: String = ""
    var isCompleted: Bool = false
}

struct Task: Identifiable, Codable {
    var id = UUID()
    var title: String = ""
    var isDone: Bool = false
}

struct User: Identifiable, Codable {
    var id = UUID()
    var name: String = ""
    var email: String = ""
}

struct Post: Identifiable, Codable {
    var id = UUID()
    var title: String = ""
    var body: String = ""
}

struct AppData: Codable {
    var items: [Item] = []
}

typealias AppModel = Item
typealias DataModel = Item
typealias Model = Item
