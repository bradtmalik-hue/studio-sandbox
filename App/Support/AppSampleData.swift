import Foundation

enum AppSampleData {
    private static func date(daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    }

    static let vehicleProfile = AppVehicleProfile(
        name: "我的爱车",
        initialOdometer: 12000,
        maintenanceIntervalKm: 5000
    )

    static let fuelRecords: [AppFuelRecord] = [
        AppFuelRecord(date: date(daysAgo: 120), odometer: 12000, cost: 350, liters: 42.5),
        AppFuelRecord(date: date(daysAgo: 95), odometer: 12540, cost: 330, liters: 40.2),
        AppFuelRecord(date: date(daysAgo: 70), odometer: 13120, cost: 355, liters: 43.0),
        AppFuelRecord(date: date(daysAgo: 45), odometer: 13680, cost: 340, liters: 41.5),
        AppFuelRecord(date: date(daysAgo: 20), odometer: 14260, cost: 360, liters: 43.8),
        AppFuelRecord(date: date(daysAgo: 3), odometer: 14800, cost: 335, liters: 41.0)
    ]

    static let maintenanceRecords: [AppMaintenanceRecord] = [
        AppMaintenanceRecord(date: date(daysAgo: 85), mileage: 13000, amount: 580, itemName: "更换机油机滤"),
        AppMaintenanceRecord(date: date(daysAgo: 15), mileage: 14300, amount: 260, itemName: "四轮定位")
    ]
}