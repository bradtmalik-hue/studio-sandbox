import Foundation

struct BrewLogBean: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var roaster: String
    var notes: String
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        name: String = "",
        roaster: String = "",
        notes: String = "",
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.roaster = roaster
        self.notes = notes
        self.isArchived = isArchived
    }
}