import Foundation

struct AppMaintenanceRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var mileage: Double
    var amount: Double
    var itemName: String

    init(
        id: UUID = UUID(),
        date: Date = .now,
        mileage: Double,
        amount: Double,
        itemName: String
    ) {
        self.id = id
        self.date = date
        self.mileage = mileage
        self.amount = amount
        self.itemName = itemName
    }

    /// 根据保养间隔计算下一次保养里程
    func nextMaintenanceMileage(serviceInterval: Double) -> Double {
        max(mileage + serviceInterval, mileage)
    }

    /// 判断当前里程是否已经达到或超过下一次保养里程
    func isMaintenanceDue(currentMileage: Double, serviceInterval: Double) -> Bool {
        currentMileage >= nextMaintenanceMileage(serviceInterval: serviceInterval)
    }

    /// 月份标识，用于按月分组展示
    var monthKey: String {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        return String(format: "%04d-%02d", year, month)
    }
}