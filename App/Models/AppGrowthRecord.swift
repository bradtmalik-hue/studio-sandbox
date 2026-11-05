import Foundation

struct AppGrowthRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var heightCm: Double
    var weightKg: Double

    /// 月度标识，用于按月分组，格式 yyyy-MM
    var monthIdentifier: String {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        return String(format: "%04d-%02d", year, month)
    }

    init(heightCm: Double, weightKg: Double, date: Date = Date(), id: UUID = UUID()) {
        self.id = id
        self.date = date
        self.heightCm = heightCm
        self.weightKg = weightKg
    }
}