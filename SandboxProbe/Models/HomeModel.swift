import Foundation

/// One record. Fields come from the requirement description.
struct HomeItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var note: String = ""
    var createdAt: Date = Date()
}
