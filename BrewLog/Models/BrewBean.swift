import Foundation

struct BrewBean: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var roaster: String
    var notes: String

    init(id: UUID = UUID(), name: String, roaster: String, notes: String = "") {
        self.id = id
        self.name = name
        self.roaster = roaster
        self.notes = notes
    }
}