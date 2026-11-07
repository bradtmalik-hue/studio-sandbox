import SwiftUI

struct AppPage2View: View {
    @EnvironmentObject var store: AppHydrationStore
    @State private var searchText = ""
    @State private var filter: AppPage2Filter = .all
    @State private var selectedRecord: AppWaterRecord?
    @State private var addingRecord = false

    private enum AppPage2Filter: String, CaseIterable, Identifiable {
        case all = "全部"
        case hit = "达标"
        case miss = "未达标"
        var id: String { rawValue }
    }

    var filteredRecords: [AppWaterRecord] {
        let records = searchText.isEmpty ? store.records : store.records.filter {
            $0.note.localizedCaseInsensitiveContains(searchText) ||
            $0.container.localizedCaseInsensitiveContains(searchText) ||
            String(Int($0.amount)).contains(searchText)
        }
        return records
    }

    private var groups: [AppPage2DayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredRecords) { calendar.startOfDay(for: $0.date) }
        return grouped.map { day, records in
            AppPage2DayGroup(day: day, records: records.sorted { $0.date > $1.date })
        }
        .filter { group in
            switch filter {
            case .all:
                return true
            case .hit:
                return group.total >= 2000
            case .miss:
                return group.total < 2000
            }
        }
        .sorted { $0.day > $1.day }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    AppPage2EmptyView(add: { addingRecord = true })
                } else if filteredRecords.isEmpty {
                    AppPage2NoResultsView()
                } else {
                    List {
                        AppPage2SummaryCard(records: filteredRecords)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)

                        ForEach(groups) { group in
                            Section {
                                ForEach(group.records) { record in
                                    AppPage2RecordRow(record: record)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedRecord = record
                                        }
                                        .swipeActions {
                                            Button(role: .destructive) {
                                                delete(record)
                                            } label: {
                                                Label("删除", systemImage: "trash")
                                            }
                                        }
                                }
                            } header: {
                                AppPage2SectionHeader(group: group)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("历史")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索容器、备注或数量")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("筛选", selection: $filter) {
                        ForEach(AppPage2Filter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .sheet(item: $selectedRecord) { record in
                AppPage2RecordEditSheet(record: record)
            }
            .sheet(isPresented: $addingRecord) {
                AppPage2AddSheet()
            }
        }
    }

    func delete(_ record: AppWaterRecord) {
        store.records.removeAll { $0.id == record.id }
        store.save()
    }
}

private struct AppPage2DayGroup: Identifiable {
    let day: Date
    let records: [AppWaterRecord]

    var id: Date { day }

    var total: Double {
        records.reduce(0) { $0 + $1.amount }
    }
}

private enum AppPage2Formatters {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    static func day(_ date: Date) -> String {
        dayFormatter.string(from: date)
    }

    static func time(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    static func monthDay(_ date: Date) -> String {
        monthDayFormatter.string(from: date)
    }
}

private struct AppPage2SummaryCard: View {
    let records: [AppWaterRecord]

    var total: Double {
        records.reduce(0) { $0 + $1.amount }
    }

    private var latestDate: Date? {
        records.max { $0.date < $1.date }?.date
    }

    var body: some View {
        HStack(spacing: 14) {
            Image("sample1")
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text("历史饮水")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(records.count) 条记录 · 共 \(Int(total)) ml")
                    .font(.title3.weight(.semibold))
                Text("最近：\(latestDate.map { AppPage2Formatters.monthDay($0) } ?? "暂无")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.blue.opacity(0.15), lineWidth: 1))
    }
}

private struct AppPage2RecordRow: View {
    let record: AppWaterRecord

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "drop.fill")
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(record.amount)) ml")
                    .font(.headline)
                Text(record.container)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(AppPage2Formatters.time(record.date))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct AppPage2SectionHeader: View {
    let group: AppPage2DayGroup

    var body: some View {
        HStack {
            Text(AppPage2Formatters.day(group.day))
                .font(.headline)

            Spacer()

            Text("\(Int(group.total)) ml / 2000 ml")
                .font(.subheadline)
                .foregroundColor(group.total >= 2000 ? .green : .secondary)

            Image(systemName: group.total >= 2000 ? "checkmark.seal.fill" : "drop.fill")
                .foregroundColor(group.total >= 2000 ? .green : .blue)
        }
    }
}

private struct AppPage2EmptyView: View {
    let add: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("还没有历史记录", systemImage: "drop.triangle")
        } description: {
            Text("去今天页面记录第一杯水，之后这里会按天整理")
        } actions: {
            Button("添加一条记录", action: add)
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct AppPage2NoResultsView: View {
    var body: some View {
        ContentUnavailableView {
            Label("没有匹配结果", systemImage: "magnifyingglass")
        } description: {
            Text("换个关键词或筛选条件试试")
        }
    }
}

private struct AppPage2RecordEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppHydrationStore

    private let original: AppWaterRecord
    private let containers = ["普通杯 250ml", "水壶 500ml", "大瓶 750ml", "小杯 150ml"]

    @State private var date: Date
    @State private var amountText: String
    @State private var amount: Double
    @State private var container: String
    @State private var note: String

    init(record: AppWaterRecord) {
        self.original = record
        _date = State(initialValue: record.date)
        _amountText = State(initialValue: String(Int(record.amount)))
        _amount = State(initialValue: record.amount)
        _container = State(initialValue: record.container)
        _note = State(initialValue: record.note)
    }

    private var isValid: Bool {
        guard let value = Double(amountText), value > 0 else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("记录详情") {
                    DatePicker("时间", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Picker("容器", selection: $container) {
                        ForEach(containers, id: \.self) { container in
                            Text(container)
                        }
                    }
                    TextField("饮水量（ml）", text: $amountText)
                        .keyboardType(.numberPad)
                    Stepper("快速调整：\(Int(amount)) ml", value: $amount, in: 50...5000, step: 50)
                    TextField("备注", text: $note)
                }

                Section {
                    Button("保存修改") {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("编辑记录")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onChange(of: amount) { newValue in
                if Double(amountText) != newValue {
                    amountText = String(Int(newValue))
                }
            }
            .onChange(of: amountText) { newValue in
                if let value = Double(newValue), value != amount {
                    amount = value
                }
            }
        }
    }

    func save() {
        guard let newAmount = Double(amountText), newAmount > 0 else { return }
        if let index = store.records.firstIndex(where: { $0.id == original.id }) {
            store.records[index] = AppWaterRecord(id: original.id)
            store.save()
        }
        dismiss()
    }
}

private struct AppPage2AddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppHydrationStore

    private let containers = ["普通杯 250ml", "水壶 500ml", "大瓶 750ml", "小杯 150ml"]

    @State private var date = Date()
    @State private var amountText = "250"
    @State private var amount = 250.0
    @State private var container = "普通杯 250ml"
    @State private var note = ""

    private var isValid: Bool {
        guard let value = Double(amountText), value > 0 else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("新记录") {
                    DatePicker("时间", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Picker("容器", selection: $container) {
                        ForEach(containers, id: \.self) { container in
                            Text(container)
                        }
                    }
                    TextField("饮水量（ml）", text: $amountText)
                        .keyboardType(.numberPad)
                    Stepper("快速调整：\(Int(amount)) ml", value: $amount, in: 50...5000, step: 50)
                    TextField("备注", text: $note)
                }

                Section {
                    Button("添加记录") {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("添加记录")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onChange(of: amount) { newValue in
                if Double(amountText) != newValue {
                    amountText = String(Int(newValue))
                }
            }
            .onChange(of: amountText) { newValue in
                if let value = Double(newValue), value != amount {
                    amount = value
                }
            }
        }
    }

    func save() {
        guard let newAmount = Double(amountText), newAmount > 0 else { return }
        let newRecord = AppWaterRecord(id: UUID())
        store.records.append(newRecord)
        store.save()
        dismiss()
    }
}