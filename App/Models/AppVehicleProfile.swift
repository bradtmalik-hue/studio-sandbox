import Foundation

struct AppVehicleProfile: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var brand: String
    var model: String
    var initialOdometer: Double
    var maintenanceIntervalKm: Double
    var fuelType: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "我的爱车",
        brand: String = "",
        model: String = "",
        initialOdometer: Double = 0,
        maintenanceIntervalKm: Double = 5000,
        fuelType: String = "92",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.model = model
        self.initialOdometer = initialOdometer
        self.maintenanceIntervalKm = maintenanceIntervalKm
        self.fuelType = fuelType
        self.createdAt = createdAt
    }

    func totalDistance(currentOdometer: Double) -> Double {
        max(0, currentOdometer - initialOdometer)
    }

    func nextMaintenanceOdometer(currentOdometer: Double) -> Double {
        guard maintenanceIntervalKm > 0, currentOdometer >= initialOdometer else {
            return initialOdometer + maintenanceIntervalKm
        }
        let completedIntervals = (currentOdometer - initialOdometer) / maintenanceIntervalKm
        let nextInterval = completedIntervals.rounded(.down) + 1
        return initialOdometer + nextInterval * maintenanceIntervalKm
    }

    func remainingDistanceToMaintenance(currentOdometer: Double) -> Double {
        max(0, nextMaintenanceOdometer(currentOdometer: currentOdometer) - currentOdometer)
    }
}