import SwiftUI
import Charts

private let AppPage3DateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateFormat = "MMM d"
    return formatter
}()

private let AppPage3TimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateFormat = "MMM d, HH:mm"
    return formatter
}()

enum AppPage3ChartMetric: String, CaseIterable {
    case count = "Count"
    case cost = "Cost"
}

struct AppPage3ChartPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

struct AppPage3View: View {
    @EnvironmentObject var store: AppDataStore
    @State private var chartMetric: AppPage3ChartMetric = .count
    @State private var showInfoAlert = false

    var sortedRecords: [AppMaintenanceRecord] {
        store.records.sorted { $0.date > $1.date }
    }

    var currentOdometer: Double {
        store.currentOdometer
    }

    private var totalOilingCount: Int {
        store.records.count
    }

    private var nextOilRemaining: Double {
        let interval = store.reminderSettings.intervalKm
        guard interval > 0 else { return 0 }
        let last = store.reminderSettings.lastServiceOdometerKm
        let remaining = interval - (currentOdometer - last)
        return max(0, remaining)
    }

    private var oilProgress: Double {
        let interval = store.reminderSettings.intervalKm
        guard interval > 0 else { return 0 }
        return min(1, max(0, nextOilRemaining / interval))
    }

    private var bikeChainInfo: String {
        if let comp = store.records.map(\.component).last {
            return "Road Bike · \(comp)"
        } else {
            return "Road Bike · Chain A"
        }
    }

    private var monthlyRideKm: Double {
        let calendar = Calendar.current
        let now = Date()
        let monthRecords = store.records.filter {
            calendar.component(.month, from: $0.date) == calendar.component(.month, from: now) &&
            calendar.component(.year, from: $0.date) == calendar.component(.year, from: now)
        }
        guard let first = monthRecords.min(by: { $0.date < $1.date }),
              let last = monthRecords.max(by: { $0.date < $1.date }) else { return 0 }
        return last.odometerKm - first.odometerKm
    }

    private var monthlyOilingCount: Int {
        let calendar = Calendar.current
        let now = Date()
        return store.records.filter {
            calendar.component(.month, from: $0.date) == calendar.component(.month, from: now) &&
            calendar.component(.year, from: $0.date) == calendar.component(.year, from: now)
        }.count
    }

    private var recentRecords: [AppMaintenanceRecord] {
        Array(sortedRecords.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.s2) {
                    if store.records.isEmpty {
                        AppPage3EmptyStateView()
                    } else {
                        header
                        mileageCard
                        nextOilCard
                        rowCards
                        chartSection
                        recentSection
                    }
                }
                .padding(.horizontal, AppTheme.s2)
                .padding(.bottom, 96)
            }
            .background(AppTheme.bg)
            .navigationTitle("Statistics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showInfoAlert = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .alert("Statistics", isPresented: $showInfoAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("All data is stored locally.")
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Statistics")
                .font(AppTheme.fontTitle)
                .foregroundColor(AppTheme.text)
            Spacer()
            Text(bikeChainInfo)
                .font(AppTheme.fontLabel)
                .foregroundColor(AppTheme.dim)
        }
    }

    private var mileageCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.s2) {
            Text("Chain Total Mileage")
                .font(AppTheme.fontLabel)
                .foregroundColor(AppTheme.dim)
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text(String(format: "%.0f", currentOdometer))
                    .font(AppTheme.fontNumber)
                    .foregroundColor(AppTheme.text)
                Text(" km")
                    .font(AppTheme.fontSection)
                    .foregroundColor(AppTheme.dim)
            }
            Text("Since last chain replacement, \(totalOilingCount) oiling records")
                .font(AppTheme.fontCaption)
                .foregroundColor(AppTheme.dim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.s3)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
    }

    private var nextOilCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.s2) {
            HStack {
                Text("Next Oiling Due")
                    .font(AppTheme.fontLabel)
                    .foregroundColor(AppTheme.dim)
                Spacer()
                Text("\(String(format: "%.0f", nextOilRemaining)) km left")
                    .font(AppTheme.fontLabel)
                    .foregroundColor(AppTheme.text)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.surfaceAlt)
                    Capsule().fill(AppTheme.accent)
                        .frame(width: geometry.size.width * oilProgress)
                }
                .frame(height: 10)
            }
            HStack {
                if let latest = store.latestRecord {
                    Text("Last oiling \(AppPage3DateFormatter.string(from: latest.date)) · Ridden \(String(format: "%.0f", currentOdometer - store.reminderSettings.lastServiceOdometerKm)) km")
                        .font(AppTheme.fontCaption)
                        .foregroundColor(AppTheme.dim)
                    Spacer()
                    Text("Target \(String(format: "%.0f", store.reminderSettings.intervalKm)) km")
                        .font(AppTheme.fontCaption)
                        .foregroundColor(AppTheme.dim)
                }
            }
        }
        .padding(AppTheme.s3)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
    }

    private var rowCards: some View {
        HStack(spacing: AppTheme.s2) {
            AppPage3SmallStatTile(title: "This Month Ride", value: String(format: "%.0f", monthlyRideKm), unit: "km")
            AppPage3SmallStatTile(title: "This Month Oiling", value: "\(monthlyOilingCount)", unit: "times")
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s2) {
            HStack {
                Text("6-Month Trend")
                    .font(AppTheme.fontSection)
                    .foregroundColor(AppTheme.text)
                Spacer()
                Picker("Metric", selection: $chartMetric) {
                    ForEach(AppPage3ChartMetric.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            AppPage3MonthlyChart(records: store.records, metric: chartMetric, points: "", value: 0)
        }
        .padding(AppTheme.s3)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s2) {
            Text("Recent Maintenance")
                .font(AppTheme.fontSection)
                .foregroundColor(AppTheme.text)
            VStack(spacing: 0) {
                ForEach(recentRecords) { record in
                    AppPage3RecordRow(record: record)
                        .swipeActions {
                            Button(role: .destructive) {
                                if let idx = store.records.firstIndex(where: { $0.id == record.id }) {
                                    store.records.remove(at: idx)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    if record.id != recentRecords.last?.id {
                        Divider()
                    }
                }
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
        }
    }
}

struct AppPage3SmallStatTile: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.fontLabel)
                .foregroundColor(AppTheme.dim)
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text(value)
                    .font(AppTheme.fontTitle)
                    .foregroundColor(AppTheme.text)
                Text(" \(unit)")
                    .font(AppTheme.fontSection)
                    .foregroundColor(AppTheme.dim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.s3)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
    }
}

struct AppPage3RecordRow: View {
    let record: AppMaintenanceRecord

    var body: some View {
        HStack(spacing: AppTheme.s2) {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.type.rawValue)
                    .font(AppTheme.fontBody)
                    .foregroundColor(AppTheme.text)
                Text(record.component)
                    .font(AppTheme.fontCaption)
                    .foregroundColor(AppTheme.dim)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f km", record.odometerKm))
                    .font(AppTheme.fontLabel)
                    .foregroundColor(AppTheme.text)
                Text(AppPage3TimeFormatter.string(from: record.date))
                    .font(AppTheme.fontCaption)
                    .foregroundColor(AppTheme.dim)
            }
        }
        .padding(AppTheme.s2)
    }
}

struct AppPage3EmptyStateView: View {
    var body: some View {
        VStack(spacing: AppTheme.s4) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundColor(AppTheme.dim)
            Text("No maintenance records yet")
                .font(AppTheme.fontSection)
                .foregroundColor(AppTheme.text)
            Text("Add your first service record to see statistics.")
                .font(AppTheme.fontBody)
                .foregroundColor(AppTheme.dim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.s6)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
    }
}

struct AppPage3MonthlyChart: View {
    let records: [AppMaintenanceRecord]
    let metric: AppPage3ChartMetric

    var data: [AppPage3ChartPoint] {
        let calendar = Calendar.current
        let now = Date()
        var points: [AppPage3ChartPoint] = []
        for offset in 0..<6 {
            guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: now) else { continue }
            let month = calendar.component(.month, from: monthDate)
            let year = calendar.component(.year, from: monthDate)
            let monthRecords = records.filter {
                calendar.component(.month, from: $0.date) == month &&
                calendar.component(.year, from: $0.date) == year
            }
            let value: Double
            switch metric {
            case .count:
                value = Double(monthRecords.count)
            case .cost:
                value = monthRecords.reduce(0) { $0 + $1.cost }
            }
            let shortMonthSymbols = calendar.shortMonthSymbols
            let label = month >= 1 && month <= shortMonthSymbols.count ? shortMonthSymbols[month - 1] : "\(month)"
            points.append(AppPage3ChartPoint(label: "", value: 0))
        }
        return points.reversed()
    }

    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Month", point.label),
                y: .value("Value", point.value)
            )
            .foregroundStyle(AppTheme.accent)
            .annotation(position: .top) {
                Text(String(format: "%.0f", point.value))
                    .font(AppTheme.fontCaption)
                    .foregroundColor(AppTheme.dim)
            }
        }
        .frame(height: 200)
    }
}