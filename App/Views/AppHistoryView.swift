import SwiftUI
import Combine
import Foundation

struct AppHistoryView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var filter: AppHistoryFilter = .all

    private enum AppHistoryFilter: String, CaseIterable {
        case all = "全部"
        case fuel = "加油"
        case maintenance = "保养"
    }

    private enum AppHistoryEntry: Identifiable {
        case fuel(AppFuelRecord)
        case maintenance(AppMaintenanceRecord)

        var id: UUID {
            switch self {
            case .fuel(let record):
                return record.id
            case .maintenance(let record):
                return record.id
            }
        }

        var date: Date {
            switch self {
            case .fuel(let record):
                return record.date
            case .maintenance(let record):
                return record.date
            }
        }

        var title: String {
            switch self {
            case .fuel:
                return "加油"
            case .maintenance:
                return "保养"
            }
        }

        var subtitle: String {
            switch self {
            case .fuel(let record):
                return String(format: "%.2f 升 · %.2f 元/升", record.liters, record.pricePerLiter)
            case .maintenance(let record):
                return record.itemName
            }
        }

        var odometerText: String {
            switch self {
            case .fuel(let record):
                return String(format: "%.0f km", record.odometer)
            case .maintenance(let record):
                return String(format: "%.0f km", record.mileage)
            }
        }

        var amountText: String {
            switch self {
            case .fuel(let record):
                return String(format: "%.2f 元", record.cost)
            case .maintenance(let record):
                return String(format: "%.2f 元", record.amount)
            }
        }
    }

    private struct AppMonthSection: Identifiable {
        let id: Date
        let title: String
        let entries: [AppHistoryEntry]
    }

    private var entries: [AppHistoryEntry] {
        let fuelEntries = store.fuelRecords.map { AppHistoryEntry.fuel($0) }
        let maintenanceEntries = store.maintenanceRecords.map { AppHistoryEntry.maintenance($0) }

        switch filter {
        case .all:
            return (fuelEntries + maintenanceEntries).sorted { $0.date > $1.date }
        case .fuel:
            return fuelEntries.sorted { $0.date > $1.date }
        case .maintenance:
            return maintenanceEntries.sorted { $0.date > $1.date }
        }
    }

    private var groupedEntries: [AppMonthSection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry -> Date in
            calendar.date(from: calendar.dateComponents([.year, .month], from: entry.date))!
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"

        return grouped.keys.sorted(by: >).map { monthStart in
            let items = (grouped[monthStart] ?? []).sorted { $0.date > $1.date }
            return AppMonthSection(
                id: monthStart,
                title: formatter.string(from: monthStart),
                entries: items
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("筛选", selection: $filter) {
                ForEach(AppHistoryFilter.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom, 8)

            if groupedEntries.isEmpty {
                Spacer()
                Text("暂无记录")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(groupedEntries) { section in
                        Section(header: Text(section.title)) {
                            ForEach(section.entries) { entry in
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.title)
                                            .font(.headline)
                                        Text(entry.subtitle)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text(entry.odometerText)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(entry.amountText)
                                        .font(.headline)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("历史记录")
    }
}