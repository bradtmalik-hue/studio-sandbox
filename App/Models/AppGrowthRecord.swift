import Foundation

struct AppGrowthRecord: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var date: Date
    var heightCm: Double
    var weightKg: Double

    init(id: UUID = UUID(), date: Date = Date(), heightCm: Double, weightKg: Double) {
        self.id = id
        self.date = date
        self.heightCm = heightCm
        self.weightKg = weightKg
    }

    /// 基础校验：过滤明显误输入的身高和体重。
    var isValid: Bool {
        (30...250).contains(heightCm) && (1...300).contains(weightKg)
    }

    var validationMessage: String? {
        if !(30...250).contains(heightCm) {
            return "请输入 30–250 厘米之间的身高。"
        }
        if !(1...300).contains(weightKg) {
            return "请输入 1–300 公斤之间的体重。"
        }
        return nil
    }
}