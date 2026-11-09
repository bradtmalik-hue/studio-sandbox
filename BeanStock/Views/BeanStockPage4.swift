import SwiftUI
import Charts
import Foundation

// MARK: - Period Enum
fileprivate enum BeanStockPage4Period: String, CaseIterable, Identifiable {
    case week = "This Week"
    case month = "This Month"
    case all = "All Time"

    var id: String { rawValue }
}

// MARK: - Chart Filter
fileprivate enum BeanStockPage4ChartFilter: String, CaseIterable, Identifiable {
    case consumption = "Consumption"
    case additions = "Additions"

    var id: String { rawValue }
}

// MARK: - Stat Point
fileprivate struct BeanStockPage4StatPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

// MARK: - Bag Consumption Item
fileprivate struct BeanStockPage4BagConsumption: Identifiable {
    let id: UUID
    let name: String
    let roastLevel: String
    let grams: Double
}

// MARK: - Main View
struct BeanStockPage4View: View {
    @EnvironmentObject var store: BeanStockStore
    @State private var selectedPeriod: BeanStockPage4Period = .week
    @State private var selectedChartFilter: BeanStockPage4ChartFilter = .consumption
    @State private var showingInfo = false

    var body: some View {
        NavigationStack {
            Group {
                if store.bags.isEmpty && store.records.isEmpty {
                    BeanStockPage4EmptyState()
                } else {
                    List {
                        summarySection
                        chartSection
                        categorySection
                        recentActivitySection
                    }
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 96) }
                }
            }
            .navigationTitle("Statistics")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showingInfo) {
                BeanStockPage4InfoView()
            }
        }
    }

    // MARK: - Summary Section
    private var summarySection: some View {
        Section {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    BeanStockPage4SummaryCard(
                        title: "Total Bags",
                        value: "\(store.bags.count)",
                        icon: "bag.fill",
                        color: .brown
                    )
                    BeanStockPage4SummaryCard(
                        title: "Total Stock",
                        value: String(format: "%.0f g", totalStockGrams),
                        icon: "scalemass.fill",
                        color: .green
                    )
                }
                HStack(spacing: 16) {
                    BeanStockPage4SummaryCard(
                        title: periodTitle + " Consumed",
                        value: String(format: "%.0f g", consumedInPeriod),
                        icon: "cup.and.saucer.fill",
                        color: .orange
                    )
                    BeanStockPage4SummaryCard(
                        title: "Avg / Day",
                        value: String(format: "%.1f g", averageDailyConsumption),
                        icon: "chart.bar.fill",
                        color: .blue
                    )
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Summary")
        }
    }

    private var periodTitle: String {
        switch selectedPeriod {
        case .week: return "This Week"
        case .month: return "This Month"
        case .all: return "All Time"
        }
    }

    private var periodStart: Date {
        let cal = Calendar.current
        switch selectedPeriod {
        case .week:
            return cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        case .month:
            return cal.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .all:
            return .distantPast
        }
    }

    var totalStockGrams: Double {
        store.bags.reduce(0) { $0 + $1.stockWeightGrams }
    }

    private var consumedInPeriod: Double {
        let start = periodStart
        return store.records
            .filter { $0.type == .consumption && $0.date >= start }
            .reduce(0) { $0 + $1.amountGrams }
    }

    private var averageDailyConsumption: Double {
        let days: Double
        switch selectedPeriod {
        case .week:
            days = 7
        case .month:
            days = 30
        case .all:
            if let first = store.records.map(\.date).min() {
                days = max(1, Date().timeIntervalSince(first) / 86400)
            } else {
                days = 1
            }
        }
        return consumedInPeriod / days
    }

    // MARK: - Chart Section
    private var chartSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Chart Type", selection: $selectedChartFilter) {
                    ForEach(BeanStockPage4ChartFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Period", selection: $selectedPeriod) {
                    ForEach(BeanStockPage4Period.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)

                if chartData.isEmpty {
                    BeanStockPage4NoChartDataView()
                } else {
                    Chart(chartData) { point in
                        BarMark(
                            x: .value("Day", point.label),
                            y: .value("Grams", point.value)
                        )
                        .foregroundStyle(Color.brown.gradient)
                        .annotation(position: .top) {
                            Text(String(format: "%.0f", point.value))
                                .font(.caption2)
                        }
                    }
                    .frame(height: 220)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Trend")
        }
    }

    private var chartData: [BeanStockPage4StatPoint] {
        let cal = Calendar.current
        let start: Date
        switch selectedPeriod {
        case .week:
            start = cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        case .month:
            start = cal.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .all:
            start = .distantPast
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        if selectedPeriod == .all {
            formatter.dateFormat = "MMM d"
        } else {
            formatter.dateFormat = "EEE"
        }

        let filteredRecords = store.records.filter { $0.date >= start }
            .filter { record in
                switch selectedChartFilter {
                case .consumption:
                    return record.type == .consumption
                case .additions:
                    return record.type == .addition
                }
            }

        var grouped: [Date: Double] = [:]
        if selectedPeriod == .all {
            for record in filteredRecords {
                let comps = cal.dateComponents([.year, .month], from: record.date)
                if let monthDate = cal.date(from: comps) {
                    grouped[monthDate, default: 0] += record.amountGrams
                }
            }
        } else {
            for record in filteredRecords {
                let dayStart = cal.startOfDay(for: record.date)
                grouped[dayStart, default: 0] += record.amountGrams
            }
        }

        let sortedKeys = grouped.keys.sorted()
        let points = sortedKeys.map { key -> BeanStockPage4StatPoint in
            let label = formatter.string(from: key)
            return BeanStockPage4StatPoint(label: label, value: grouped[key] ?? 0)
        }

        let nonZeroPoints = points.filter { $0.value > 0 }
        return nonZeroPoints
    }

    // MARK: - Category Section
    private var categorySection: some View {
        Section {
            if topBagsByConsumption.isEmpty {
                Text("No consumption records yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(topBagsByConsumption.prefix(5)) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.headline)
                            Text(item.roastLevel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(String(format: "%.0f g", item.grams))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.brown)
                    }
                    .padding(.vertical, 4)
                }
            }
        } header: {
            Text("Top Bags by Consumption")
        }
    }

    private var topBagsByConsumption: [BeanStockPage4BagConsumption] {
        let bagMap = Dictionary(uniqueKeysWithValues: store.bags.map { ($0.id, $0) })
        var dict: [UUID: Double] = [:]
        for record in store.records where record.type == .consumption {
            dict[record.bagID, default: 0] += record.amountGrams
        }

        return dict.compactMap { bagID, grams in
            guard let bag = bagMap[bagID] else { return nil }
            return BeanStockPage4BagConsumption(
                id: bagID,
                name: bag.name,
                roastLevel: bag.roastLevel,
                grams: grams
            )
        }
        .sorted { $0.grams > $1.grams }
    }

    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        Section {
            if recentRecords.isEmpty {
                Text("No recent activity.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recentRecords) { record in
                    BeanStockPage4ActivityRow(
                        record: record,
                        bagName: bagName(for: record.bagID)
                    )
                }
            }
        } header: {
            Text("Recent Activity")
        }
    }

    private var recentRecords: [BeanStockRecord] {
        Array(store.records.sorted { $0.date > $1.date }.prefix(5))
    }

    func bagName(for id: UUID) -> String {
        store.bags.first(where: { $0.id == id })?.name ?? "Unknown Bag"
    }
}

// MARK: - Summary Card
fileprivate struct BeanStockPage4SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Activity Row
fileprivate struct BeanStockPage4ActivityRow: View {
    let record: BeanStockRecord
    let bagName: String

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: record.date)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.type == .consumption ? "cup.and.saucer.fill" : "plus.circle.fill")
                .foregroundStyle(record.type == .consumption ? .orange : .green)
            VStack(alignment: .leading, spacing: 4) {
                Text(bagName)
                    .font(.subheadline.weight(.medium))
                Text(record.type == .consumption
                     ? String(format: "Consumed %.0f g", record.amountGrams)
                     : String(format: "Added %.0f g", record.amountGrams))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(dateString)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Empty State
fileprivate struct BeanStockPage4EmptyState: View {
    var body: some View {
        ContentUnavailableView(
            "No Statistics Yet",
            systemImage: "chart.bar.xaxis",
            description: Text("Add coffee bags and record brews to see statistics here.")
        )
    }
}

// MARK: - No Chart Data
fileprivate struct BeanStockPage4NoChartDataView: View {
    var body: some View {
        ContentUnavailableView(
            "No Chart Data",
            systemImage: "chart.bar",
            description: Text("There are no records for the selected period and type.")
        )
        .frame(height: 220)
    }
}

// MARK: - Info View
fileprivate struct BeanStockPage4InfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("About Statistics") {
                    Text("This page shows your coffee inventory and consumption trends.")
                    Text("Use the filters to switch between weekly, monthly, and all-time views.")
                    Text("Chart shows grams consumed or added over time.")
                }
                Section {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Statistics Info")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}