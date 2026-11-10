import SwiftUI
import Charts

struct AppPage4View: View {
    @EnvironmentObject var store: AppFishingStore
    @State private var searchText = ""
    @State private var sortOption: SortOption = .count
    @State private var selectedMethod: String? = nil
    @State private var selectedSpot: AppPage4SpotSummary? = nil
    @State private var showDetail = false

    enum SortOption: String, CaseIterable {
        case count = "按条数"
        case maxWeight = "按最大个体"
    }

    var filteredRecords: [AppCatchRecord] {
        store.records.filter { selectedMethod == nil || $0.method == selectedMethod }
    }

    private var summarizedSpots: [AppPage4SpotSummary] {
        let grouped = Dictionary(grouping: filteredRecords, by: { $0.spot })
        var summaries: [AppPage4SpotSummary] = []
        for (spotName, records) in grouped {
            let totalCount = records.count
            let maxWeight = records.map { $0.weightKg }.max() ?? 0
            let totalWeight = records.reduce(0) { $0 + $1.weightKg }
            summaries.append(AppPage4SpotSummary(spotName: spotName, totalCount: totalCount, maxWeight: maxWeight, totalWeight: totalWeight, averageWeight: totalWeight / Double(totalCount)))
        }
        if !searchText.isEmpty {
            summaries = summaries.filter { $0.spotName.localizedCaseInsensitiveContains(searchText) }
        }
        switch sortOption {
        case .count:
            summaries.sort { $0.totalCount > $1.totalCount }
        case .maxWeight:
            summaries.sort { $0.maxWeight > $1.maxWeight }
        }
        return summaries
    }

    private var hasData: Bool {
        !store.records.isEmpty
    }

    private var maxWeightOverall: Double {
        filteredRecords.map { $0.weightKg }.max() ?? 0
    }

    private var methodOptions: [String?] {
        [nil] + Array(Set(store.records.map { $0.method })).sorted()
    }

    var body: some View {
        NavigationStack {
            AppScreen {
                VStack(spacing: AppTheme.spacing.s6) {
                    summaryTiles
                    controls
                    if hasData {
                        chart
                        list
                    } else {
                        AppPage4Empty()
                    }
                }
            }
            .navigationTitle("钓点")
            .sheet(isPresented: $showDetail) {
                if let spot = selectedSpot {
                    AppPage4DetailSheet(spot: spot, records: recordsForSpot(spotName: spot.spotName))
                }
            }
        }
    }

    var summaryTiles: some View {
        HStack(spacing: AppTheme.spacing.s4) {
            AppStatTile(title: "钓点数量", value: "\(summarizedSpots.count)", unit: "个")
            AppStatTile(title: "最大个体", value: String(format: "%.2f", maxWeightOverall), unit: "kg")
            AppStatTile(title: "总条数", value: "\(filteredRecords.count)", unit: "条")
        }
    }

    private var controls: some View {
        VStack(spacing: AppTheme.spacing.s4) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.colors.dim)
                TextField("搜索钓点", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(AppTheme.fontBody)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.colors.dim)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppTheme.spacing.s3)
            .background(AppTheme.colors.surfaceAlt)
            .cornerRadius(AppTheme.rSmall)

            Picker("排序", selection: $sortOption) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)

            Picker("方法", selection: $selectedMethod) {
                ForEach(methodOptions, id: \.self) { method in
                    Text(method ?? "全部方法").tag(method)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.horizontal, AppTheme.spacing.s4)
    }

    var chart: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.spacing.s4) {
                Text("各钓点条数")
                    .font(AppTheme.fontSection)
                    .foregroundColor(AppTheme.colors.text)
                Chart(summarizedSpots.map { AppPage4ChartPoint(spot: $0.spotName, count: $0.totalCount) }) { point in
                    BarMark(
                        x: .value("钓点", point.spot),
                        y: .value("条数", point.count)
                    )
                    .foregroundStyle(AppTheme.colors.accent)
                    .annotation(position: .top) {
                        Text("\(point.count)")
                            .font(AppTheme.fontCaption)
                            .foregroundColor(AppTheme.colors.dim)
                    }
                }
                .frame(height: 220)
            }
            .padding(AppTheme.spacing.s4)
        }
        .padding(.horizontal, AppTheme.spacing.s4)
    }

    var list: some View {
        List {
            ForEach(summarizedSpots) { spot in
                Button {
                    selectedSpot = spot
                    showDetail = true
                } label: {
                    AppPage4Row(spot: spot)
                }
                .buttonStyle(.plain)
                .listRowBackground(AppTheme.colors.surface)
            }
        }
        .listStyle(.insetGrouped)
        .contentMargins(.bottom, 96, for: .scrollContent)
    }

    private func recordsForSpot(spotName: String) -> [AppCatchRecord] {
        store.records.filter { $0.spot == spotName }
    }
}

struct AppPage4Row: View {
    let spot: AppPage4SpotSummary

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.s2) {
            HStack {
                Text(spot.spotName)
                    .font(AppTheme.fontBody)
                    .foregroundColor(AppTheme.colors.text)
                Spacer()
                AppBadge(text: "最大 \(String(format: "%.2f", spot.maxWeight)) kg")
            }
            HStack {
                Text("条数：\(spot.totalCount)")
                    .font(AppTheme.fontLabel)
                    .foregroundColor(AppTheme.colors.dim)
                Spacer()
                Text("总重：\(String(format: "%.2f", spot.totalWeight)) kg")
                    .font(AppTheme.fontLabel)
                    .foregroundColor(AppTheme.colors.dim)
            }
        }
        .padding(AppTheme.spacing.s3)
        .background(AppTheme.colors.surface)
        .cornerRadius(AppTheme.rCard)
    }
}

struct AppPage4Empty: View {
    var body: some View {
        AppEmptyState(icon: "fish", title: "还没有钓点记录", message: "去记一笔吧，鱼获会自动汇总到这里")
    }
}

struct AppPage4DetailSheet: View {
    let spot: AppPage4SpotSummary
    let records: [AppCatchRecord]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    AppEmptyState(icon: "tray", title: "没有记录", message: "该钓点暂无收获")
                } else {
                    List(records) { record in
                        VStack(alignment: .leading, spacing: AppTheme.spacing.s2) {
                            Text(record.species)
                                .font(AppTheme.fontBody)
                            Text("\(record.date, formatter: AppPage4DateFormatter)")
                                .font(AppTheme.fontLabel)
                                .foregroundColor(AppTheme.colors.dim)
                            HStack {
                                Text("\(record.weightKg, specifier: "%.2f") kg")
                                Spacer()
                                Text("\(record.lengthCm, specifier: "%.1f") cm")
                            }
                            .font(AppTheme.fontLabel)
                            .foregroundColor(AppTheme.colors.dim)
                        }
                        .padding(AppTheme.spacing.s2)
                    }
                }
            }
            .navigationTitle(spot.spotName)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

private let AppPage4DateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M月d日 HH:mm"
    return formatter
}()

struct AppPage4SpotSummary: Identifiable {
    let id = UUID()
    let spotName: String
    let totalCount: Int
    let maxWeight: Double
    let totalWeight: Double
    let averageWeight: Double
}

struct AppPage4ChartPoint: Identifiable {
    let id = UUID()
    let spot: String
    let count: Int
}