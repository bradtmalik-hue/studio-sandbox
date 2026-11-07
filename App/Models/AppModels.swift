import Foundation
import SwiftUI

struct AppWaterRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = Date()
    var amount: Double = 0
    var note: String? = nil
}
