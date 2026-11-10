import SwiftUI
import Charts
import Foundation

struct AppPage4ChartItem: Identifiable {
    let id = UUID()
    let tankName: String
    let type: String
    let value: Double
}

struct AppPage4TankStats: Identifiable {
    let id: UUID
    let tankName: String
    let waterChangeCount: Int
    let feedingCount: Int
}

enum AppPage4Filter: String, CaseIterable, Identifiable {
    case all = "All"
    case water = "Water Change"
    case feeding = "Feeding"
    var id: String { rawValue }
}

enum AppPage4DisplayMode: String, CaseIterable, Identifiable {
    case chart = "Chart"
    case list = "List"
    var id: String { rawValue }
}

struct AppPage4View: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @State private var selectedFilter: AppPage4Filter = .all
    @State private var displayMode: AppPage4DisplayMode = .chart

    var dark: Bool { scheme == .dark }

    private var monthInterval: DateInterval {
        Calendar.current.dateInterval(of: .month, for: Date()) ?? DateInterval(start: Date(), duration: 0)
    }

    var monthLogs: [AppLogEntry] {
        store.logs.filter { monthInterval.contains($0.date) }
    }

    private var totalWaterChanges: Int {
        monthLogs.filter { $0.kind.rawValue.lowercased().contains("water") }.count
    }

    private var totalFeedings: Int {
        monthLogs.filter { $0.kind.rawValue.lowercased().contains("feed") }.count
    }

    private var activeTankCount: Int {
        Set(monthLogs.map(\.tankID)).count
    }

    private var allTankStats: [AppPage4TankStats] {
        store.tanks.map { tank in
            let tankLogs = monthLogs.filter { $0.tankID == tank.id }
            let water = tankLogs.filter { $0.kind.rawValue.lowercased().contains("water") }.count
            let feeding = tankLogs.filter { $0.kind.rawValue.lowercased().contains("feed") }.count
            return AppPage4TankStats(
                id: tank.id,
                tankName: tank.name,
                waterChangeCount: water,
                feedingCount: feeding
            )
        }
    }

    private var filteredTankStats: [AppPage4TankStats] {
        switch selectedFilter {
        case .all:
            return allTankStats
        case .water:
            return allTankStats.filter { $0.waterChangeCount > 0 }
        case .feeding:
            return allTankStats.filter { $0.feedingCount > 0 }
        }
    }

    private var chartData: [AppPage4ChartItem] {
        guard !monthLogs.isEmpty else { return [] }
        return store.tanks.flatMap { tank -> [AppPage4ChartItem] in
            let tankLogs = monthLogs.filter { $0.tankID == tank.id }
            let water = tankLogs.filter { $0.kind.rawValue.lowercased().contains("water") }.count
            let feeding = tankLogs.filter { $0.kind.rawValue.lowercased().contains("feed") }.count
            var items: [AppPage4ChartItem] = []
            if water > 0 {
                items.append(AppPage4ChartItem(tankName: "", type: "", value: 0))
            }
            if feeding > 0 {
                items.append(AppPage4ChartItem(tankName: "", type: "", value: 0))
            }
            return items
        }
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            AppScreen {
                ScrollView {
                    VStack(spacing: AppLayout.stack) {
                        VStack(spacing: AppLayout.xs) {
                            Text("Statistics")
                                .font(AppType.font(.title))
                                .foregroundStyle(AppTheme.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(monthTitle)
                                .font(AppType.font(.body))
                                .foregroundStyle(AppTheme.dim)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        HStack(spacing: AppLayout.gutter) {
                            AppStatTile(title: "Water Changes", value: "\(totalWaterChanges)", unit: "times")
                            AppStatTile(title: "Feedings", value: "\(totalFeedings)", unit: "times")
                            AppStatTile(title: "Active Tanks", value: "\(activeTankCount)", unit: "tanks")
                        }

                        Picker("Display", selection: $displayMode) {
                            ForEach(AppPage4DisplayMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(AppPage4Filter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)

                        if displayMode == .chart {
                            if chartData.isEmpty {
                                ContentUnavailableView(
                                    "No Activity",
                                    systemImage: "chart.bar",
                                    description: Text("No water changes or feedings this month. Use the buttons on the home page to log your first entry.")
                                )
                                .frame(maxWidth: .infinity)
                                .padding(AppLayout.inset)
                            } else {
                                AppCard {
                                    VStack(alignment: .leading, spacing: AppLayout.stack) {
                                        Text("Tank Activity")
                                            .font(AppType.font(.headline))
                                            .foregroundStyle(AppTheme.text)
                                        Chart(chartData) { item in
                                            BarMark(
                                                x: .value("Tank", item.tankName),
                                                y: .value("Count", item.value)
                                            )
                                            .foregroundStyle(by: .value("Type", item.type))
                                            .annotation(position: .top) {
                                                Text("\(Int(item.value))")
                                                    .font(AppType.font(.caption))
                                                    .foregroundStyle(AppTheme.dim)
                                            }
                                        }
                                        .chartLegend(position: .bottom)
                                        .frame(height: 240)
                                    }
                                    .padding(AppLayout.inset)
                                }
                            }
                        } else {
                            if filteredTankStats.isEmpty {
                                ContentUnavailableView(
                                    "No Tanks",
                                    systemImage: "drop.triangle",
                                    description: Text("No tanks match the current filter. Add a tank or adjust the filter.")
                                )
                                .frame(maxWidth: .infinity)
                                .padding(AppLayout.inset)
                            } else {
                                AppCard {
                                    VStack(spacing: AppLayout.stack) {
                                        ForEach(filteredTankStats) { stat in
                                            AppRowItem(
                                                icon: "water.waves",
                                                title: stat.tankName,
                                                subtitle: "Water: \(stat.waterChangeCount) · Feed: \(stat.feedingCount)"
                                            )
                                            if stat.id != filteredTankStats.last?.id {
                                                Divider().overlay(AppTheme.stroke)
                                            }
                                        }
                                    }
                                    .padding(AppLayout.inset)
                                }
                            }
                        }

                        Color.clear.frame(height: 96)
                    }
                    .padding(AppLayout.page)
                }
                .contentMargins(.bottom, 96, for: .scrollContent)
                .AppAppear()
            }
            .navigationTitle("Statistics")
        }
    }
}

#Preview {
    AppPage4View(items: "")
        .environmentObject(AppStore())
}