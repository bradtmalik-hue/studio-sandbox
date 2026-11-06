import SwiftUI

enum AppMetric: String, CaseIterable, Identifiable {
    case height = "身高"
    case weight = "体重"
    var id: String { rawValue }
}

enum AppDateFormatter {
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()
    
    static let medium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()
    
    static let month: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()
}

struct AppDashboardView: View {
    @EnvironmentObject var store: AppGrowthStore
    @State private var showingAdd = false
    
    var sortedRecords: [AppGrowthRecord] {
        store.records.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if sortedRecords.isEmpty {
                    AppEmptyStateView(
                        icon: "figure.and.child.holdinghands",
                        title: "还没有成长记录",
                        message: "点击右上角 + 记录第一条身高体重，曲线会自动生成。"
                    )
                } else {
                    List {
                        Section {
                            AppSummaryView(records: store.records)
                        }
                        Section("最近记录") {
                            ForEach(sortedRecords) { record in
                                AppRecordRow(record: record)
                            }
                            .onDelete(perform: deleteRecords)
                        }
                    }
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("成长日志")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AppAddRecordView()
            }
        }
    }
    
    private func deleteRecords(at offsets: IndexSet) {
        for index in offsets {
            store.delete(sortedRecords[index])
        }
    }
}

struct AppRecordRow: View {
    let record: AppGrowthRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppDateFormatter.medium.string(from: record.date))
                    .font(.subheadline.weight(.semibold))
                if let note = record.note as? String, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f cm", record.height))
                    .font(.subheadline.weight(.medium))
                Text(String(format: "%.1f kg", record.weight))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AppSummaryView: View {
    let records: [AppGrowthRecord]
    
    var latestRecord: AppGrowthRecord? {
        records.max(by: { $0.date < $1.date })
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                AppStatCard(
                    title: "最新身高",
                    value: latestRecord.map { String(format: "%.1f", $0.height) } ?? "--",
                    unit: "cm",
                    color: .blue
                )
                AppStatCard(
                    title: "最新体重",
                    value: latestRecord.map { String(format: "%.1f", $0.weight) } ?? "--",
                    unit: "kg",
                    color: .green
                )
            }
            if let latest = latestRecord {
                Text("更新于 \(AppDateFormatter.short.string(from: latest.date))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AppStatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(color)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct AppAddRecordView: View {
    @EnvironmentObject var store: AppGrowthStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var date = Date()
    @State private var heightText = ""
    @State private var weightText = ""
    @State private var note = ""
    
    var height: Double? {
        Double(heightText.replacingOccurrences(of: ",", with: "."))
    }
    
    var weight: Double? {
        Double(weightText.replacingOccurrences(of: ",", with: "."))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("记录日期") {
                    DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                Section("身高体重") {
                    TextField("身高（cm）", text: $heightText)
                        .keyboardType(.decimalPad)
                    TextField("体重（kg）", text: $weightText)
                        .keyboardType(.decimalPad)
                }
                Section("备注（可选）") {
                    TextField("例如：体检后测量", text: $note)
                }
            }
            .navigationTitle("添加记录")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(height == nil || weight == nil)
                }
            }
        }
    }
    
    func save() {
        guard let height, let weight else { return }
        let record = AppGrowthRecord(date: date, height: height, weight: weight, note: note)
        store.add(record)
        dismiss()
    }
}

struct AppGrowthChartView: View {
    @EnvironmentObject var store: AppGrowthStore
    @State private var metric: AppMetric = .height
    
    private var monthlyPoints: [AppMonthlyPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.records) { record -> Date in
            let components = calendar.dateComponents([.year, .month], from: record.date)
            return calendar.date(from: components) ?? record.date
        }
        let points = grouped.map { (month, records) -> AppMonthlyPoint in
            let average: Double
            switch metric {
            case .height:
                average = records.map(\.height).reduce(0, +) / Double(records.count)
            case .weight:
                average = records.map(\.weight).reduce(0, +) / Double(records.count)
            }
            return AppMonthlyPoint(date: month, value: average)
        }
        return points.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    AppEmptyStateView(
                        icon: "chart.xyaxis.line",
                        title: "还没有曲线数据",
                        message: "添加身高体重记录后，这里会自动生成按月成长曲线。"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            Picker("指标", selection: $metric) {
                                ForEach(AppMetric.allCases) { metric in
                                    Text(metric.rawValue).tag(metric)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
                            AppChartView(
                                points: monthlyPoints,
                                color: metric == .height ? .blue : .green,
                                unit: metric == .height ? "cm" : "kg"
                            )
                            .padding(.horizontal)
                            
                            AppMonthlyStatsView(points: monthlyPoints, metric: metric)
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 96)
                    }
                }
            }
            .navigationTitle("成长曲线")
        }
    }
}

struct AppMonthlyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct AppChartView: View {
    let points: [AppMonthlyPoint]
    let color: Color
    let unit: String
    
    var body: some View {
        VStack(spacing: 8) {
            if points.isEmpty {
                Text("暂无数据")
                    .foregroundStyle(.secondary)
            } else {
                GeometryReader { geometry in
                    let minValue = points.map(\.value).min() ?? 0
                    let maxValue = points.map(\.value).max() ?? 1
                    let range = max(maxValue - minValue, 0.1)
                    let padding: CGFloat = 24
                    let chartWidth = geometry.size.width - padding * 2
                    let chartHeight = geometry.size.height - padding * 2
                    let stepX = points.count > 1 ? chartWidth / CGFloat(points.count - 1) : 0
                    
                    let mappedPoints = points.enumerated().map { index, point -> CGPoint in
                        let x = padding + (points.count > 1 ? CGFloat(index) * stepX : chartWidth / 2)
                        let y = padding + chartHeight * (1 - CGFloat((point.value - minValue) / range))
                        return CGPoint(x: x, y: y)
                    }
                    
                    ZStack {
                        ForEach(0..<5, id: \.self) { index in
                            let y = padding + chartHeight * CGFloat(index) / 4
                            Path { path in
                                path.move(to: CGPoint(x: padding, y: y))
                                path.addLine(to: CGPoint(x: geometry.size.width - padding, y: y))
                            }
                            .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
                        }
                        
                        if mappedPoints.count > 1 {
                            Path { path in
                                path.move(to: mappedPoints[0])
                                for point in mappedPoints.dropFirst() {
                                    path.addLine(to: point)
                                }
                            }
                            .stroke(color, lineWidth: 2)
                        }
                        
                        ForEach(Array(mappedPoints.enumerated()), id: \.offset) { index, point in
                            Circle()
                                .fill(color)
                                .frame(width: 8, height: 8)
                                .position(point)
                            Text(String(format: "%.1f", points[index].value))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .position(x: point.x, y: point.y - 14)
                        }
                    }
                }
                .frame(height: 220)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(points) { point in
                            Text(AppDateFormatter.month.string(from: point.date))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
    }
}

struct AppMonthlyStatsView: View {
    let points: [AppMonthlyPoint]
    let metric: AppMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("按月平均")
                .font(.headline)
            if points.isEmpty {
                Text("暂无数据")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(points) { point in
                    HStack {
                        Text(AppDateFormatter.month.string(from: point.date))
                        Spacer()
                        Text(String(format: "%.1f %@", point.value, metric == .height ? "cm" : "kg"))
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct AppEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(.blue)
            Text(title)
                .font(.title2.weight(.semibold))
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}