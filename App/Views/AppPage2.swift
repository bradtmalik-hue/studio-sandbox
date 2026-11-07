import SwiftUI
import Foundation

private struct AppPage2Formatters {
    static let date: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "zh_CN")
        df.dateFormat = "M月d日"
        return df
    }()
}

struct AppPage2View: View {
    @EnvironmentObject private var store: AppStore
    @State private var searchText = ""
    @State private var selectedPetFilter = "全部宠物"
    @State private var sheetMode: AppPage2SheetMode? = nil

    private var allRecords: [AppVaccineRecord] {
        store.vaccineRecords
    }

    private var petNameMap: [UUID: String] {
        Dictionary(uniqueKeysWithValues: store.pets.map { ($0.id, $0.name) })
    }

    private var filteredRecords: [AppVaccineRecord] {
        var records = allRecords
        if selectedPetFilter != "全部宠物" {
            records = records.filter { petNameMap[$0.petID] == selectedPetFilter }
        }
        if !searchText.isEmpty {
            records = records.filter {
                $0.vaccineName.localizedCaseInsensitiveContains(searchText) ||
                (petNameMap[$0.petID] ?? "").localizedCaseInsensitiveContains(searchText) ||
                $0.manufacturer.localizedCaseInsensitiveContains(searchText) ||
                $0.batchNumber.localizedCaseInsensitiveContains(searchText)
            }
        }
        return records.sorted { $0.nextDueDate < $1.nextDueDate }
    }

    var upcomingCount: Int {
        let now = Date()
        let thirtyDaysLater = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now
        return allRecords.filter { $0.nextDueDate >= now && $0.nextDueDate < thirtyDaysLater }.count
    }

    private var latestVaccination: AppVaccineRecord? {
        allRecords.max(by: { $0.vaccinationDate < $1.vaccinationDate })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppPage2SummaryCard(
                    total: allRecords.count,
                    upcoming: upcomingCount,
                    latestDate: latestVaccination?.vaccinationDate
                )
                .padding(.horizontal)
                .padding(.top, 8)

                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("搜索疫苗、宠物或批号", text: $searchText)
                            .autocorrectionDisabled(true)
                    }
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                    if !store.pets.isEmpty {
                        Menu {
                            Picker("选择宠物", selection: $selectedPetFilter) {
                                Text("全部宠物").tag("全部宠物")
                                ForEach(store.pets) { pet in
                                    Text(pet.name).tag(pet.name)
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.primary)
                                .font(.title3)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                if store.pets.isEmpty {
                    ContentUnavailableView {
                        Label("请先添加宠物", systemImage: "pawprint")
                    } description: {
                        Text("疫苗记录需要关联宠物档案")
                    }
                } else if filteredRecords.isEmpty {
                    ContentUnavailableView {
                        Label("暂无疫苗记录", systemImage: "syringe")
                    } description: {
                        Text("点击下方按钮添加第一条疫苗记录")
                    } actions: {
                        Button("添加记录") {
                            sheetMode = .add
                        }
                    }
                } else {
                    List {
                        ForEach(filteredRecords) { record in
                            AppPage2Row(record: record, petName: petNameMap[record.petID] ?? "未知宠物")
                                .swipeActions {
                                    Button(role: .destructive) {
                                        deleteRecord(record)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                                .onTapGesture {
                                    sheetMode = .edit(record)
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("疫苗记录")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        sheetMode = .add
                    } label: {
                        Label("添加", systemImage: "plus")
                    }
                    .disabled(store.pets.isEmpty)
                }
            }
            .sheet(item: $sheetMode) { mode in
                AppPage2RecordEditorView(mode: mode)
            }
        }
    }

    private func deleteRecord(_ record: AppVaccineRecord) {
        if let index = store.vaccineRecords.firstIndex(where: { $0.id == record.id }) {
            store.vaccineRecords.remove(at: index)
        }
    }
}

struct AppPage2SummaryCard: View {
    let total: Int
    let upcoming: Int
    let latestDate: Date?

    var body: some View {
        HStack(spacing: 16) {
            AppPage2MetricView(number: total, unit: "总记录", icon: "list.bullet.clipboard")
            Divider()
            AppPage2MetricView(number: upcoming, unit: "30天内到期", icon: "calendar.badge.exclamationmark")
            Divider()
            VStack(spacing: 4) {
                if let latest = latestDate {
                    Text(AppPage2Formatters.date.string(from: latest))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                } else {
                    Text("—")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                Text("最近接种")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct AppPage2MetricView: View {
    let number: Int
    let unit: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.caption)
                Text("\(number)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
            }
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AppPage2Row: View {
    let record: AppVaccineRecord
    let petName: String

    var daysRemaining: Int {
        let components = Calendar.current.dateComponents([.day], from: Date(), to: record.nextDueDate)
        return components.day ?? 0
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.vaccineName)
                    .font(.headline)
                Text(petName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if !record.batchNumber.isEmpty {
                    Text("批号: \(record.batchNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("接种: \(AppPage2Formatters.date.string(from: record.vaccinationDate))")
                    .font(.caption)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("下次: \(AppPage2Formatters.date.string(from: record.nextDueDate))")
                    .font(.caption)
                if daysRemaining >= 0 {
                    Text("剩 \(daysRemaining) 天")
                        .font(.caption2)
                        .padding(4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                } else {
                    Text("过期 \(abs(daysRemaining)) 天")
                        .font(.caption2)
                        .padding(4)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

enum AppPage2SheetMode: Identifiable {
    case add
    case edit(AppVaccineRecord)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let record):
            return record.id.uuidString
        }
    }
}

struct AppPage2RecordEditorView: View {
    let mode: AppPage2SheetMode
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var vaccineName: String
    @State private var selectedPetID: UUID?
    @State private var vaccinationDate: Date
    @State private var nextDueDate: Date
    @State private var manufacturer: String
    @State private var batchNumber: String
    @State private var veterinarian: String
    @State private var notes: String
    @State private var addReminder: Bool

    init(mode: AppPage2SheetMode) {
        self.mode = mode
        switch mode {
        case .add:
            _vaccineName = State(initialValue: "")
            _selectedPetID = State(initialValue: nil)
            _vaccinationDate = State(initialValue: Date())
            _nextDueDate = State(initialValue: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date())
            _manufacturer = State(initialValue: "")
            _batchNumber = State(initialValue: "")
            _veterinarian = State(initialValue: "")
            _notes = State(initialValue: "")
            _addReminder = State(initialValue: true)
        case .edit(let record):
            _vaccineName = State(initialValue: record.vaccineName)
            _selectedPetID = State(initialValue: record.petID)
            _vaccinationDate = State(initialValue: record.vaccinationDate)
            _nextDueDate = State(initialValue: record.nextDueDate)
            _manufacturer = State(initialValue: record.manufacturer)
            _batchNumber = State(initialValue: record.batchNumber)
            _veterinarian = State(initialValue: record.veterinarian)
            _notes = State(initialValue: record.notes)
            _addReminder = State(initialValue: false)
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var selectedPetName: String {
        if let id = selectedPetID, let pet = store.pets.first(where: { $0.id == id }) {
            return pet.name
        }
        return ""
    }

    private var isSaveDisabled: Bool {
        vaccineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        selectedPetID == nil ||
        vaccinationDate > nextDueDate
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("疫苗信息") {
                    TextField("疫苗名称（必填）", text: $vaccineName)
                    Picker("宠物", selection: $selectedPetID) {
                        Text("请选择宠物").tag(UUID?.none)
                        ForEach(store.pets) { pet in
                            Text(pet.name).tag(pet.id as UUID?)
                        }
                    }
                    if store.pets.isEmpty {
                        Text("请先在宠物档案中添加宠物")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    TextField("生产厂家", text: $manufacturer)
                    TextField("疫苗批号", text: $batchNumber)
                    TextField("兽医", text: $veterinarian)
                }
                Section("接种日期") {
                    DatePicker("接种日期", selection: $vaccinationDate, displayedComponents: .date)
                    DatePicker("下次到期日", selection: $nextDueDate, displayedComponents: .date)
                    if vaccinationDate > nextDueDate {
                        Text("到期日不能早于接种日期")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                Section("备注") {
                    TextField("备注", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section {
                    Toggle(isOn: $addReminder) {
                        Label("保存后加入提醒", systemImage: "bell.badge")
                    }
                    if isEditing {
                        Text("编辑时默认不重复添加提醒，如需更新请手动开启")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑疫苗记录" : "添加疫苗记录")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(isSaveDisabled)
                }
            }
        }
    }

    func save() {
        guard let petID = selectedPetID else { return }
        let trimmedName = vaccineName.trimmingCharacters(in: .whitespacesAndNewlines)
        let newRecord = AppVaccineRecord(
            id: UUID(),
            petID: petID,
            vaccineName: trimmedName,
            manufacturer: manufacturer,
            batchNumber: batchNumber,
            vaccinationDate: vaccinationDate,
            nextDueDate: nextDueDate,
            veterinarian: veterinarian,
            notes: notes,
            createdAt: Date()
        )

        switch mode {
        case .add:
            store.vaccineRecords.append(newRecord)
        case .edit(let oldRecord):
            if let index = store.vaccineRecords.firstIndex(where: { $0.id == oldRecord.id }) {
                store.vaccineRecords[index] = newRecord
            } else {
                store.vaccineRecords.append(newRecord)
            }
        }

        dismiss()
    }
}