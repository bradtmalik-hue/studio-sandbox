import Foundation
import Combine

struct AppPersistedData: Codable {
    var vehicleProfile: AppVehicleProfile
    var fuelRecords: [AppFuelRecord]
    var maintenanceRecords: [AppMaintenanceRecord]
}

final class AppDataStore: ObservableObject {
    @Published var vehicleProfile: AppVehicleProfile
    @Published var fuelRecords: [AppFuelRecord]
    @Published var maintenanceRecords: [AppMaintenanceRecord]

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docDir.appendingPathComponent("CarCareLogData.json")
        vehicleProfile = AppVehicleProfile(
            id: UUID(),
            name: "未设置",
            brand: "",
            model: "",
            initialOdometer: 0,
            maintenanceIntervalKm: 10000,
            fuelType: "汽油",
            createdAt: Date()
        )
        fuelRecords = []
        maintenanceRecords = []
        load()
    }

    // MARK: - Persistence
    func save() {
        let persisted = AppPersistedData(vehicleProfile: vehicleProfile, fuelRecords: fuelRecords, maintenanceRecords: maintenanceRecords)
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(persisted)
            try data.write(to: fileURL)
        } catch {
            print("保存失败: \(error)")
        }
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        decoder.dateDecodingStrategy = .iso8601
        do {
            let data = try Data(contentsOf: fileURL)
            let persisted = try decoder.decode(AppPersistedData.self, from: data)
            vehicleProfile = persisted.vehicleProfile
            fuelRecords = persisted.fuelRecords
            maintenanceRecords = persisted.maintenanceRecords
        } catch {
            print("加载失败: \(error)")
        }
    }

    // MARK: - Add / Delete
    func addFuelRecord(_ record: AppFuelRecord) {
        fuelRecords.append(record)
        save()
    }

    func addMaintenanceRecord(_ record: AppMaintenanceRecord) {
        maintenanceRecords.append(record)
        save()
    }

    func deleteFuelRecord(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            fuelRecords.remove(at: index)
        }
        save()
    }

    func deleteMaintenanceRecord(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            maintenanceRecords.remove(at: index)
        }
        save()
    }

    func updateVehicleProfile(_ profile: AppVehicleProfile) {
        vehicleProfile = profile
        save()
    }

    // MARK: - Monthly totals
    struct MonthlyTotals {
        var fuelAmount: Double = 0
        var maintenanceAmount: Double = 0
        var totalAmount: Double = 0
        var fuelLiters: Double = 0
        var distanceTraveled: Double = 0
        var fuelCostPerKilometer: Double = 0
        var fuelConsumptionLitersPer100KM: Double = 0
    }

    func monthlyTotals(for month: Date) -> MonthlyTotals {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: month)
        let start = monthInterval?.start ?? month
        let end = monthInterval?.end ?? month

        let monthFuelRecords = fuelRecords.filter { $0.date >= start && $0.date < end }
        let monthMaintenanceRecords = maintenanceRecords.filter { $0.date >= start && $0.date < end }

        let fuelAmount = monthFuelRecords.reduce(0.0) { $0 + $1.cost }
        let maintenanceAmount = monthMaintenanceRecords.reduce(0.0) { $0 + $1.amount }
        let fuelLiters = monthFuelRecords.reduce(0.0) { $0 + $1.liters }

        var distanceTraveled: Double = 0
        if let minOdo = monthFuelRecords.map(\.odometer).min(),
           let maxOdo = monthFuelRecords.map(\.odometer).max(),
           maxOdo > minOdo {
            distanceTraveled = maxOdo - minOdo
        }

        var totals = MonthlyTotals()
        totals.fuelAmount = fuelAmount
        totals.maintenanceAmount = maintenanceAmount
        totals.totalAmount = fuelAmount + maintenanceAmount
        totals.fuelLiters = fuelLiters
        totals.distanceTraveled = distanceTraveled

        if distanceTraveled > 0 {
            totals.fuelCostPerKilometer = (fuelAmount + maintenanceAmount) / distanceTraveled
            if fuelLiters > 0 {
                totals.fuelConsumptionLitersPer100KM = (fuelLiters / distanceTraveled) * 100
            }
        }
        return totals
    }

    // MARK: - Interval fuel consumption
    struct IntervalFuelEfficiency {
        var litersUsed: Double
        var distanceKM: Double
        var litersPer100KM: Double
    }

    func intervalFuelEfficiency() -> IntervalFuelEfficiency {
        guard fuelRecords.count >= 2 else {
            return IntervalFuelEfficiency(litersUsed: 0, distanceKM: 0, litersPer100KM: 0)
        }
        let sorted = fuelRecords.sorted { $0.odometer < $1.odometer }
        var totalLiters: Double = 0
        var totalDistance: Double = 0
        for (index, record) in sorted.enumerated() {
            if index == 0 { continue }
            let previous = sorted[index - 1]
            let distance = record.odometer - previous.odometer
            if distance > 0 {
                totalDistance += distance
                totalLiters += record.liters
            }
        }
        let efficiency = totalDistance > 0 ? (totalLiters / totalDistance) * 100 : 0.0
        return IntervalFuelEfficiency(litersUsed: totalLiters, distanceKM: totalDistance, litersPer100KM: efficiency)
    }

    // MARK: - Cost per kilometer
    struct CostPerKilometer {
        var totalCost: Double
        var totalDistance: Double
        var costPerKilometer: Double
    }

    func costPerKilometer() -> CostPerKilometer {
        let fuelCost = fuelRecords.reduce(0.0) { $0 + $1.cost }
        let maintenanceCost = maintenanceRecords.reduce(0.0) { $0 + $1.amount }
        let totalCost = fuelCost + maintenanceCost

        var totalDistance = vehicleProfile.initialOdometer
        if totalDistance <= 0 {
            let fuelOdo = fuelRecords.map(\.odometer)
            let maintOdo = maintenanceRecords.map(\.mileage)
            if let minFuel = fuelOdo.min(), let maxFuel = fuelOdo.max() {
                totalDistance = maxFuel - minFuel
            } else if let minMaint = maintOdo.min(), let maxMaint = maintOdo.max() {
                totalDistance = maxMaint - minMaint
            }
        }

        let c = totalDistance > 0 ? totalCost / totalDistance : 0.0
        return CostPerKilometer(totalCost: totalCost, totalDistance: totalDistance, costPerKilometer: c)
    }

    // MARK: - Maintenance reminder
    struct MaintenanceReminder {
        var nextMaintenanceOdometer: Double
        var currentOdometer: Double
        var remainingKM: Double
        var isDue: Bool
    }

    func maintenanceReminder() -> MaintenanceReminder {
        let sortedMaintenance = maintenanceRecords.sorted(by: { (a: AppMaintenanceRecord, b: AppMaintenanceRecord) -> Bool in
            a.mileage > b.mileage
        })
        let lastMaintenanceOdometer = sortedMaintenance.first?.mileage ?? 0
        let interval = vehicleProfile.maintenanceIntervalKm
        let nextOdo = lastMaintenanceOdometer + interval

        let currentOdo = max(
            vehicleProfile.initialOdometer,
            fuelRecords.map(\.odometer).max() ?? 0,
            maintenanceRecords.map(\.mileage).max() ?? 0
        )
        let remaining = nextOdo - currentOdo
        return MaintenanceReminder(
            nextMaintenanceOdometer: nextOdo,
            currentOdometer: currentOdo,
            remainingKM: remaining,
            isDue: remaining <= 0
        )
    }
}