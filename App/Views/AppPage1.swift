import Foundation
import SwiftUI

struct AppWaterRecord: Identifiable, Codable {
    let id: UUID
    var date: Date
    var amountML: Int
    var note: String
}

class AppDataStore: ObservableObject {
    @Published var records: [AppWaterRecord] = []
    @Published var dailyGoalML: Int = 2000

    private let recordsKey = "records"
    private let goalKey = "dailyGoalML"

    init() {
        load()
    }

    func save() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: recordsKey)
        }
        UserDefaults.standard.set(dailyGoalML, forKey: goalKey)
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([AppWaterRecord].self, from: data) {
            records = decoded
        }
        if UserDefaults.standard.object(forKey: goalKey) != nil {
            dailyGoalML = UserDefaults.standard.integer(forKey: goalKey)
        }
    }
}

struct AppPage1View: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedFilter: AppPage1Filter = .all
    @State private var searchText = ""
    @State private var editingRecord: AppWaterRecord?
    @State private var showingEdit = false

    private var todayRecords: [AppWaterRecord] {
        store.records
            .filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date > $1.date }
    }

    var filteredRecords: [AppWaterRecord] {
        todayRecords.filter { record in
            if !searchText.isEmpty && !record.note.localizedCaseInsensitiveContains(searchText) {
                return false
            }

            switch selectedFilter {
            case .all:
                return true
            case .small:
                return record.amountML < 300
            case .large:
                return record.amountML >= 300
            }
        }
    }

    private var totalToday: Int {
        todayRecords.reduce(0) { $0 + $1.amountML }
    }

    private var progress: Double {
        guard store.dailyGoalML > 0 else { return 0 }
        return min(Double(totalToday) / Double(store.dailyGoalML), 1.0)
    }

    private var lastRecordText: String {
        guard let latest = todayRecords.first else { return "" }
        return AppPage1View.timeFormatter.string(from: latest.date)
    }

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    Section {
                        AppPage1HeroCard(
                            total: totalToday,
                            goal: store.dailyGoalML,
                            progress: progress,
                            lastRecordText: lastRecordText,
                            onAdd: addWater
                        )
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    Section {
                        Picker("筛选", selection: $selectedFilter) {
                            ForEach(AppPage1Filter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section {
                        ForEach(filteredRecords, id: \.id) { record in
                            Button {
                                editingRecord = record
                                showingEdit = true
                            } label: {
                                AppPage1Row(record: record)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(record)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text("今日记录")
                            Spacer()
                            Text("\(filteredRecords.count) 条")
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .contentMargins(.bottom, 96, for: .scrollContent)
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "搜索备注"
                )

                if todayRecords.isEmpty {
                    AppPage1EmptyState(onAdd: addWater)
                } else if filteredRecords.isEmpty {
                    ContentUnavailableView {
                        Label("没有符合条件的记录", systemImage: "magnifyingglass")
                    } description: {
                        Text("试试调整筛选条件或搜索词")
                    }
                }
            }
            .navigationTitle("今天")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addWater()
                    } label: {
                        Label("添加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEdit) {
                if let editingRecord {
                    AppPage1EditSheet(record: editingRecord) { updated in
                        saveUpdated(updated)
                    }
                }
            }
        }
    }

    private func addWater() {
        let newRecord = AppWaterRecord()
        store.records.append(newRecord)
        store.save()
    }

    func delete(_ record: AppWaterRecord) {
        store.records.removeAll { $0.id == record.id }
        store.save()
    }

    private func saveUpdated(_ updated: AppWaterRecord) {
        if let index = store.records.firstIndex(where: { $0.id == updated.id }) {
            store.records[index] = updated
            store.save()
        }
    }
}

struct AppPage1HeroCard: View {
    let total: Int
    let goal: Int
    let progress: Double
    let lastRecordText: String
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日饮水")
                        .font(.title3.bold())
                    Text("共 \(total) 毫升")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "drop.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
            }

            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 18)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.blue,
                            style: StrokeStyle(lineWidth: 18, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 4) {
                        Text("\(Int(progress * 100))%")
                            .font(.title.bold())
                        Text("目标 \(goal)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 150, height: 150)

                VStack(alignment: .leading, spacing: 10) {
                    Text("目标 \(goal) 毫升")
                        .font(.headline)
                    Text("剩余 \(max(goal - total, 0)) 毫升")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if !lastRecordText.isEmpty {
                        Text("最近 \(lastRecordText)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Button(action: onAdd) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("快速添加 250 毫升")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct AppPage1Row: View {
    let record: AppWaterRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.note.isEmpty ? "喝水记录" : record.note)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(record.amountML) 毫升")
                    .font(.subheadline)
                Text(AppPage1View.timeFormatter.string(from: record.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
}

struct AppPage1EmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("今天还没有喝水记录", systemImage: "drop")
        } description: {
            Text("点击下方按钮添加今天第一杯水")
        } actions: {
            Button("添加 250 毫升", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
    }
}

struct AppPage1EditSheet: View {
    @Environment(\.dismiss) private var dismiss

    let record: AppWaterRecord
    let onSave: (AppWaterRecord) -> Void

    @State private var amountText: String
    @State private var note: String
    @State private var date: Date
    @State private var showValidationAlert = false

    init(record: AppWaterRecord, onSave: @escaping (AppWaterRecord) -> Void) {
        self.record = record
        self.onSave = onSave
        _amountText = State(initialValue: String(record.amountML))
        _note = State(initialValue: record.note)
        _date = State(initialValue: record.date)
    }

    private var amountValue: Int? {
        Int(amountText)
    }

    private var isValid: Bool {
        guard let amount = amountValue else { return false }
        return amount > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("毫升") {
                    TextField("毫升", text: $amountText)
                        .keyboardType(.numberPad)
                }

                Section("备注") {
                    TextField("备注", text: $note)
                }

                Section("时间") {
                    DatePicker(
                        "时间",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                if let amount = amountValue, amount <= 0 {
                    Section {
                        Text("毫升数必须大于 0")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("编辑记录")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("无效输入", isPresented: $showValidationAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text("请输入大于 0 的毫升数")
            }
        }
    }

    func save() {
        guard let amount = amountValue, amount > 0 else {
            showValidationAlert = true
            return
        }

        let updated = AppWaterRecord()
        onSave(updated)
        dismiss()
    }
}

enum AppPage1Filter: String, CaseIterable, Identifiable, Hashable {
    case all = "全部"
    case small = "少于300"
    case large = "300及以上"

    var id: String { rawValue }
}