import SwiftUI

private struct AppStatCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(tint)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(tint.opacity(0.12))
        )
    }
}

struct AppStatisticsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedMonth: Date = Date()

    private var calendar: Calendar { Calendar.current }

    private var monthFuelRecords: [AppFuelRecord] {
        store.fuelRecords.filter { calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
    }

    private var monthMaintenanceRecords: [AppMaintenanceRecord] {
        store.maintenanceRecords.filter { calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
    }

    private var totalFuelCost: Double {
        monthFuelRecords.reduce(0) { $0 + $1.cost }
    }

    private var totalMaintenanceCost: Double {
        monthMaintenanceRecords.reduce(0) { $0 + $1.amount }
    }

    private var distanceDriven: Double {
        let fuelDistances = store.fuelRecords.map { (date: $0.date, mileage: $0.odometer) }
        let maintenanceDistances = store.maintenanceRecords.map { (date: $0.date, mileage: $0.mileage) }
        let allDistances = (fuelDistances + maintenanceDistances).sorted { $0.date < $1.date }
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let previous = allDistances.last(where: { $0.date < startOfMonth })
        let monthDistances = allDistances.filter { calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
        let startMileage = previous?.mileage ?? monthDistances.first?.mileage ?? 0
        let endMileage = monthDistances.last?.mileage ?? startMileage
        return max(0, endMileage - startMileage)
    }

    private var costPerKilometer: Double {
        let total = totalFuelCost + totalMaintenanceCost
        guard distanceDriven > 0 else { return 0 }
        return total / distanceDriven
    }

    private var averageFuelConsumption: Double {
        let sortedFuel = store.fuelRecords.sorted { $0.date < $1.date }
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let previousFuel = sortedFuel.last(where: { $0.date < startOfMonth })
        let monthFuel = monthFuelRecords.sorted { $0.date < $1.date }
        let startMileage = previousFuel?.odometer ?? monthFuel.first?.odometer ?? 0
        let endMileage = monthFuel.last?.odometer ?? startMileage
        let distance = max(0, endMileage - startMileage)
        let liters = monthFuel.reduce(0) { $0 + $1.liters }
        guard distance > 0 else { return 0 }
        return (liters / distance) * 100
    }

    private var hasRecords: Bool {
        !monthFuelRecords.isEmpty || !monthMaintenanceRecords.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    monthPicker

                    if hasRecords {
                        statisticsGrid
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var monthPicker: some View {
        DatePicker(
            "选择月份",
            selection: $selectedMonth,
            displayedComponents: .date
        )
        .datePickerStyle(.compact)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.12))
        )
    }

    private var statisticsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            AppStatCard(
                title: "油费合计",
                value: Self.currencyText(totalFuelCost),
                icon: "fuelpump.fill",
                tint: .orange
            )
            AppStatCard(
                title: "保养合计",
                value: Self.currencyText(totalMaintenanceCost),
                icon: "wrench.and.screwdriver.fill",
                tint: .blue
            )
            AppStatCard(
                title: "每公里花费",
                value: Self.costText(costPerKilometer),
                icon: "yensign.circle.fill",
                tint: .green
            )
            AppStatCard(
                title: "区间油耗",
                value: Self.fuelConsumptionText(averageFuelConsumption),
                icon: "gauge.medium",
                tint: .purple
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("本月还没有记录")
                .font(.headline)
            Text("去“记一笔”添加加油或保养记录，这里会显示本月养车花费。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    static func currencyText(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: NSNumber(value: value)) ?? "¥0.00"
    }

    static func costText(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.locale = Locale(identifier: "zh_CN")
        return (formatter.string(from: NSNumber(value: value)) ?? "¥0.00") + "/km"
    }

    static func fuelConsumptionText(_ value: Double) -> String {
        return String(format: "%.2f L/100km", value)
    }
}