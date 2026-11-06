import SwiftUI
import Combine
import Charts

private enum AppDateFormatter {
    static let zhFull: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter
    }()

    static let zhDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter
    }()

    static let zhShortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月dd日"
        return formatter
    }()
}

struct AppEmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 46, weight: .medium))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct AppChildCard: View {
    let child: AppChildProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(child.name)
                .font(.headline)
                .foregroundStyle(.primary)
            Text("出生日期：\(AppDateFormatter.zhShortDate.string(from: child.birthDate))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct AppRecordRow: View {
    let record: AppGrowthRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppDateFormatter.zhFull.string(from: record.date))
                .font(.subheadline)
                .foregroundStyle(.primary)
            HStack(spacing: 16) {
                Label("身高 \(record.heightCm, specifier: "%.1f") cm", systemImage: "ruler")
                Label("体重 \(record.weightKg, specifier: "%.2f") kg", systemImage: "scalemass")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AppHomeView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingAddRecord = false
    @State private var showingAddChild = false

    var sortedRecords: [AppGrowthRecord] {
        store.records.sorted { $0.date > $1.date }
    }

    private var latestRecords: [AppGrowthRecord] {
        Array(sortedRecords.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if store.profile.name.isEmpty {
                        AppEmptyStateView(
                            icon: "person.2",
                            title: "还没有孩子档案",
                            message: "先添加一个孩子，再开始记录身高体重吧。"
                        )
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                AppChildCard(child: store.profile)
                                Button {
                                    showingAddChild = true
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                        Text("编辑孩子")
                                            .font(.caption)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    if sortedRecords.isEmpty {
                        AppEmptyStateView(
                            icon: "chart.xyaxis.line",
                            title: "还没有成长记录",
                            message: "点击右上角加号，记录第一条身高体重。"
                        )
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("最近记录")
                                .font(.title3.bold())
                                .padding(.horizontal)

                            ForEach(latestRecords) { record in
                                AppRecordRow(record: record)
                                Divider()
                            }
                            .padding(.horizontal)
                        }
                    }

                    Color.clear.frame(height: 96)
                }
                .padding(.top)
            }
            .navigationTitle("成长日记")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if store.profile.name.isEmpty {
                            showingAddChild = true
                        } else {
                            showingAddRecord = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRecord) {
                AppAddRecordView()
            }
            .sheet(isPresented: $showingAddChild) {
                AppAddChildView()
            }
        }
    }
}

struct AppRecordListView: View {
    @EnvironmentObject var store: AppStore

    var sortedRecords: [AppGrowthRecord] {
        store.records.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                if sortedRecords.isEmpty {
                    AppEmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "暂无记录",
                        message: "去首页添加第一条成长记录吧。"
                    )
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(sortedRecords) { record in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(store.profile.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            AppRecordRow(record: record)
                        }
                    }
                    .onDelete(perform: deleteRecords)
                }

                if !sortedRecords.isEmpty {
                    Section {
                        Color.clear.frame(height: 80)
                    }
                }
            }
            .navigationTitle("记录")
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }

    func deleteRecords(at offsets: IndexSet) {
        let ids = offsets.map { sortedRecords[$0].id }
        store.records.removeAll { ids.contains($0.id) }
        store.save()
    }
}

struct AppAddRecordView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var heightText = ""
    @State private var weightText = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                if store.profile.name.isEmpty {
                    Section {
                        Text("请先添加孩子档案")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("日期") {
                        DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    }

                    Section("身体数据") {
                        TextField("身高 (cm)", text: $heightText)
                            .keyboardType(.decimalPad)
                        TextField("体重 (kg)", text: $weightText)
                            .keyboardType(.decimalPad)
                    }

                    if let validationMessage {
                        Section {
                            Text(validationMessage)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("添加记录")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { addRecord() }
                        .disabled(store.profile.name.isEmpty)
                }
            }
        }
    }

    func addRecord() {
        guard let height = Double(heightText), let weight = Double(weightText) else {
            validationMessage = "请输入有效的数字。"
            return
        }

        let record = AppGrowthRecord(
            id: UUID(),
            date: date,
            heightCm: height,
            weightKg: weight,
            note: nil
        )
        store.records.append(record)
        store.save()
        dismiss()
    }
}

struct AppAddChildView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var birthDate = Date()
    @State private var gender: AppGender = .male
    @State private var validationMessage: String?
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("姓名或昵称", text: $name)
                    DatePicker("出生日期", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                    Picker("性别", selection: $gender) {
                        Text("男孩").tag(AppGender.male)
                        Text("女孩").tag(AppGender.female)
                    }
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("孩子档案")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { addChild() }
                }
            }
            .onAppear {
                if !didLoad {
                    name = store.profile.name
                    birthDate = store.profile.birthDate
                    gender = store.profile.gender
                    didLoad = true
                }
            }
        }
    }

    private func addChild() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = "请输入孩子姓名或昵称。"
            return
        }

        let child = AppChildProfile(
            name: trimmedName,
            birthDate: birthDate,
            gender: gender
        )
        store.profile = child
        store.save()
        dismiss()
    }
}

struct AppChildListView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingAddChild = false

    var body: some View {
        NavigationStack {
            List {
                if store.profile.name.isEmpty {
                    AppEmptyStateView(
                        icon: "person.2",
                        title: "没有孩子档案",
                        message: "点击右上角加号添加孩子。"
                    )
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.profile.name)
                            .font(.headline)
                        Text("出生日期：\(AppDateFormatter.zhShortDate.string(from: store.profile.birthDate))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("孩子档案")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddChild = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddChild) {
                AppAddChildView()
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }
}

struct AppGrowthChartView: View {
    @EnvironmentObject var store: AppStore

    @State private var metric: ChartMetric = .height

    enum ChartMetric: String, CaseIterable {
        case height = "身高"
        case weight = "体重"
    }

    private var filteredRecords: [AppGrowthRecord] {
        store.records.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("指标", selection: $metric) {
                    ForEach(ChartMetric.allCases, id: \.self) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                if filteredRecords.count < 2 {
                    AppEmptyStateView(
                        icon: "chart.xyaxis.line",
                        title: "数据不足",
                        message: "至少需要两次记录才能绘制曲线。"
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    chart
                        .frame(maxHeight: .infinity)
                }
            }
            .padding()
            .navigationTitle("成长曲线")
        }
    }

    private var chart: some View {
        Chart {
            ForEach(filteredRecords) { record in
                LineMark(
                    x: .value("日期", record.date),
                    y: .value(metric.rawValue, metric == .height ? record.heightCm : record.weightKg)
                )
                .foregroundStyle(.blue)
            }
        }
    }
}