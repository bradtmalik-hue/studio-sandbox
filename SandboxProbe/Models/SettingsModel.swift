import Foundation

/// One record. Fields come from the requirement description.
struct SettingsItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var flag: Bool = false
    var createdAt: Date = Date()
}
