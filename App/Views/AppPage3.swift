import SwiftUI
import Charts
import Foundation

enum AppPage3Range: String, CaseIterable, Identifiable {
    case all = "全部"
    case year = "今年"
    case month = "近30天"
    var id: String { rawValue }
}

enum AppPage3Metric: String, CaseIterable, Identifiable {
    case count = "条数"
    case weight = "总重量"
    case length = "平均长度"
    var id: String { rawValue }
}

struct AppPage3BarDatum: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

fileprivate func appPage3FormattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "yyyy年M月d日"
    return formatter.string(from: date)
}

struct AppPage3ChartCard: View {
    let title: String
    let data: [AppPage3BarDatum]
    let valueFormatter: (Double) -> String

    var body: some View {
        AppCard(title: title, systemImage: "chart.bar.fill") {
            if data.isEmpty {
                Text("暂无数据")
                    .font(AppTheme.fontBody)
                    .foregroundStyle(AppTheme.dim)
                    .frame(maxWidth: .infinity, minHeight: 160, alignment: .center)
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("分类", point.label),
                        y: .value("数值", point.value)
                    )
                    .foregroundStyle(AppTheme.accent)
                    .annotation(position: .top) {
                        Text(valueFormatter(point.value))
                            .font(AppTheme.fontCaption)
                            .foregroundStyle(AppTheme.dim)
                    }
                }
                .frame(height: 220)
                .padding(.vertical, AppTheme.s2)
            }
        }
    }
}

struct AppPage3MaxDetailSheet: View {
    let record: AppCatchRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                AppCard {
                    VStack(alignment: .leading, spacing: AppTheme.s4) {
                        HStack {
                            AppBadge(text: "最大单尾", color: AppTheme.accent)
                            Spacer()
                        }
                        Text(record.species)
                            .font(AppTheme.fontNumber)
                            .foregroundStyle(AppTheme.text)
                        Text("重量 \(record.weightKg, specifier: "%.2f") kg")
                            .font(AppTheme.fontBody)
                            .foregroundStyle(AppTheme.text)
                        Text("体长 \(record.lengthCm, specifier: "%.1f") cm")
                            .font(AppTheme.fontBody)
                            .foregroundStyle(AppTheme.text)
                        Text("日期 \(appPage3FormattedDate(record.date))")
                            .font(AppTheme.fontBody)
                            .foregroundStyle(AppTheme.text)
                        Text("钓点 \(record.spot)")
                            .font(AppTheme.fontBody)
                            .foregroundStyle(AppTheme.text)
                        Text("钓法 \(record.method)")
                            .font(AppTheme.fontBody)
                            .foregroundStyle(AppTheme.text)
                        Text("备注 \(record.note.isEmpty ? "无" : record.note)")
                            .font(AppTheme.fontBody)
                            .foregroundStyle(AppTheme.text)
                    }
                    .padding(AppTheme.s2)
                }
                .padding(AppTheme.s4)
            }
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle("最大单尾")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AppPage3View: View {
    @EnvironmentObject var store: AppFishingStore
    @State private var range: AppPage3Range = .all
    @State private var metric: AppPage3Metric = .count
    @State private var releasedOnly = false
    @State private var selectedMaxRecord: AppCatchRecord?

    var filteredRecords: [AppCatchRecord] {
        var result = store.records
        let calendar = Calendar.current
        let now = Date()

        switch range {
        case .all:
            break
        case .year:
            result = result.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .year) }
        case .month:
            guard let start = calendar.date(byAdding: .day, value: -30, to: now) else { return result }
            result = result.filter { $0.date >= start }
        }

        if releasedOnly {
            result = result.filter { $0.isReleased }
        }

        return result
    }

    private var maxRecord: AppCatchRecord? {
        filteredRecords.max(by: { $0.weightKg < $1.weightKg })
    }

    private var metricTitle: String {
        switch metric {
        case .count: return "当前范围条数"
        case .weight: return "当前范围总重量"
        case .length: return "当前范围平均长度"
        }
    }

    private var metricUnit: String {
        switch metric {
        case .count: return "条"
        case .weight: return "kg"
        case .length: return "cm"
        }
    }

    private var metricValueString: String {
        let value = metricValue(for: filteredRecords)
        switch metric {
        case .count:
            return String(format: "%.0f", value)
        case .weight:
            return String(format: "%.1f", value)
        case .length:
            return String(format: "%.1f", value)
        }
    }

    private var speciesData: [AppPage3BarDatum] {
        let grouped = Dictionary(grouping: filteredRecords, by: \.species)
        let items = grouped.map { species, records in
            AppPage3BarDatum(label: "", value: 0)
        }
        return items.sorted { $0.value > $1.value }.prefix(6).map { $0 }
    }

    private var monthlyData: [AppPage3BarDatum] {
        let calendar = Calendar.current
        let now = Date()
        let grouped = Dictionary(grouping: filteredRecords) { record -> String in
            let comps = calendar.dateComponents([.year, .month], from: record.date)
            let year = comps.year ?? 0
            let month = comps.month ?? 0
            if range == .all || year != calendar.component(.year, from: now) {
                return "\(year)年\(month)月"
            } else {
                return "\(month)月"
            }
        }
        let items = grouped.map { label, records in
            AppPage3BarDatum(label: "", value: 0)
        }
        return items.sorted { $0.label < $1.label }
    }

    private func metricValue(for records: [AppCatchRecord]) -> Double {
        switch metric {
        case .count:
            return Double(records.count)
        case .weight:
            return records.reduce(0) { $0 + $1.weightKg }
        case .length:
            guard !records.isEmpty else { return 0 }
            return records.reduce(0) { $0 + $1.lengthCm } / Double(records.count)
        }
    }

    private func formatMetricValue(_ value: Double) -> String {
        switch metric {
        case .count:
            return String(format: "%.0f", value)
        case .weight:
            return String(format: "%.1f", value)
        case .length:
            return String(format: "%.1f", value)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()

                if store.records.isEmpty {
                    AppEmptyState(
                        icon: "chart.bar.xaxis",
                        title: "暂无趋势数据",
                        message: "先去记一笔收获，这里会展示鱼种和月份统计"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.s4) {
                            summaryTiles
                            filterCard
                            speciesChartCard
                            monthlyChartCard
                            maxRecordCard
                        }
                        .padding(.horizontal, AppTheme.s4)
                        .padding(.top, AppTheme.s4)
                        .contentMargins(.bottom, 96, for: .scrollContent)
                    }
                }
            }
            .navigationTitle("趋势")
            .sheet(item: $selectedMaxRecord) { record in
                AppPage3MaxDetailSheet(record: record)
            }
        }
    }

    var summaryTiles: some View {
        VStack(spacing: AppTheme.s3) {
            HStack(spacing: AppTheme.s3) {
                AppStatTile(
                    title: "总条数",
                    value: "\(filteredRecords.count)",
                    unit: "条",
                    systemImage: "number"
                )
                AppStatTile(
                    title: "最大个体",
                    value: maxRecord.map { String(format: "%.2f", $0.weightKg) } ?? "--",
                    unit: "kg",
                    systemImage: "scalemass"
                )
            }
            AppStatTile(
                title: metricTitle,
                value: metricValueString,
                unit: metricUnit,
                systemImage: "chart.bar.fill"
            )
        }
    }

    private var filterCard: some View {
        AppCard(title: "筛选", systemImage: "line.3.horizontal.decrease.circle") {
            VStack(alignment: .leading, spacing: AppTheme.s4) {
                Picker("时间范围", selection: $range) {
                    ForEach(AppPage3Range.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                Picker("统计指标", selection: $metric) {
                    ForEach(AppPage3Metric.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                Toggle(isOn: $releasedOnly) {
                    Text("仅看已放流")
                        .font(AppTheme.fontLabel)
                        .foregroundStyle(AppTheme.text)
                }
                .toggleStyle(.switch)

                HStack(spacing: AppTheme.s3) {
                    AppPrimaryButton(
                        title: "重置",
                        systemImage: "arrow.counterclockwise"
                    ) {
                        range = .all
                        metric = .count
                        releasedOnly = false
                    }

                    if maxRecord != nil {
                        AppPrimaryButton(
                            title: "最大单尾详情",
                            systemImage: "info.circle"
                        ) {
                            selectedMaxRecord = maxRecord
                        }
                    }
                }
            }
        }
    }

    private var speciesChartCard: some View {
        AppPage3ChartCard(
            title: "按鱼种统计",
            data: speciesData,
            valueFormatter: { value in
                formatMetricValue(value)
            }
        )
    }

    private var monthlyChartCard: some View {
        AppPage3ChartCard(
            title: "月度对比",
            data: monthlyData,
            valueFormatter: { value in
                formatMetricValue(value)
            }
        )
    }

    private var maxRecordCard: some View {
        Group {
            if let record = maxRecord {
                AppCard(title: "最大单尾", systemImage: "trophy") {
                    VStack(alignment: .leading, spacing: AppTheme.s2) {
                        HStack {
                            AppBadge(text: "最大", color: AppTheme.accent)
                            Spacer()
                        }
                        Text("\(record.species) · \(record.weightKg, specifier: "%.2f") kg")
                            .font(AppTheme.fontNumber)
                            .foregroundStyle(AppTheme.text)
                        Text("体长 \(record.lengthCm, specifier: "%.1f") cm")
                            .font(AppTheme.fontBody)
                            .foregroundStyle(AppTheme.text)
                        Text("\(appPage3FormattedDate(record.date)) · \(record.spot)")
                            .font(AppTheme.fontCaption)
                            .foregroundStyle(AppTheme.dim)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedMaxRecord = record
                    }
                }
            }
        }
    }
}