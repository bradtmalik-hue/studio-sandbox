import SwiftUI
import Combine
import Foundation

private enum AppPage2Format {
    static let day: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter
    }()

    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static let monthDayTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    static func amountText(_ amount: Double) -> String {
        String(format: "%.1f 克", amount)
    }
}

private enum AppPage2Sheet: Identifiable {
    case detail(AppFeedRecord)
    case add

    var id: String {
        switch self {
        case .detail(let record):
            return record.id.uuidString
        case .add:
            return "add"
        }
    }
}

struct AppPage2View: View {
    @EnvironmentObject private var store: AppStore
    @State private var searchText = ""
    @State private var selectedFoodType: String?
    @State private var activeSheet: AppPage2Sheet?

    var filteredRecords: [AppFeedRecord] {
        var records = store.feedingRecords

        if let selectedFoodType {
            records = records.filter { $0.foodType == selectedFoodType }
        }

        if !searchText.isEmpty {
            records = records.filter {
                $0.foodType.localizedCaseInsensitiveContains(searchText) ||
                $0.note.localizedCaseInsensitiveContains(searchText)
            }
        }

        return records.sorted { $0.date > $1.date }
    }

    private var groups: [AppPage2DayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredRecords) { record in
            calendar.startOfDay(for: record.date)
        }
        return grouped.map { day, records in
            AppPage2DayGroup(id: day, records: records.sorted { $0.date > $1.date })
        }
        .sorted { $0.id > $1.id }
    }

    private var foodTypeOptions: [String] {
        Array(Set(store.feedingRecords.map(\.foodType))).sorted()
    }

    private var totalAmountText: String {
        AppPage2Format.amountText(filteredRecords.reduce(0) { $0 + $1.amount })
    }

    private var lastRecordText: String {
        guard let last = filteredRecords.first else { return "—" }
        return AppPage2Format.monthDayTime.string(from: last.date)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppPage2SummaryCard(
                    recordCount: filteredRecords.count,
                    totalAmountText: totalAmountText,
                    lastRecordText: lastRecordText
                )

                filterBar

                if filteredRecords.isEmpty {
                    AppPage2EmptyViewLocal(
                        hasAnyRecords: !store.feedingRecords.isEmpty,
                        onClear: {
                            searchText = ""
                            selectedFoodType = nil
                        },
                        onAdd: {
                            activeSheet = .add
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groups) { group in
                            Section {
                                ForEach(group.records) { record in
                                    Button {
                                        activeSheet = .detail(record)
                                    } label: {
                                        AppPage2Row(record: record)
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            delete(record)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                AppPage2DayHeader(group: group)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("历史")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索食物或备注")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .add
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .add:
                    AppPage2AddViewLocal()
                case .detail(let record):
                    AppPage2DetailViewLocal(
                        record: record,
                        petName: store.settings.petName,
                        dailyTarget: store.settings.dailyTarget
                    )
                }
            }
        }
    }

    private var filterBar: some View {
        HStack(spacing: 12) {
            Menu {
                Button {
                    selectedFoodType = nil
                } label: {
                    Label(
                        "全部类型",
                        systemImage: selectedFoodType == nil ? "checkmark.circle.fill" : "circle"
                    )
                }

                if !foodTypeOptions.isEmpty {
                    Divider()
                    ForEach(foodTypeOptions, id: \.self) { type in
                        Button {
                            selectedFoodType = type
                        } label: {
                            Label(
                                type,
                                systemImage: selectedFoodType == type ? "checkmark.circle.fill" : "circle"
                            )
                        }
                    }
                }
            } label: {
                Label(
                    selectedFoodType ?? "全部类型",
                    systemImage: "line.3.horizontal.decrease.circle"
                )
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.12), in: Capsule())
            }

            if selectedFoodType != nil {
                Button("清除") {
                    selectedFoodType = nil
                }
                .font(.subheadline)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    func delete(_ record: AppFeedRecord) {
        store.objectWillChange.send()
        store.feedingRecords.removeAll { $0.id == record.id }
        store.save()
    }
}

private struct AppPage2SummaryCard: View {
    let recordCount: Int
    let totalAmountText: String
    let lastRecordText: String

    var body: some View {
        HStack(spacing: 16) {
            AppPage2MetricLabel(
                title: "总记录",
                value: "\(recordCount)",
                unit: "次",
                icon: "list.bullet.clipboard"
            )

            Divider()
                .frame(height: 40)

            AppPage2MetricLabel(
                title: "累计喂食",
                value: totalAmountText,
                unit: "",
                icon: "fork.knife"
            )

            Divider()
                .frame(height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Label("最近一次", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(lastRecordText)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

private struct AppPage2MetricLabel: View {
    let title: String
    let value: String
    let unit: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AppPage2Row: View {
    let record: AppFeedRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.title3)
                .foregroundStyle(.gray)
                .frame(width: 40, height: 40)
                .background(Color.gray.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.foodType)
                        .font(.headline)
                    Spacer()
                    Text(AppPage2Format.time.string(from: record.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text("喂食量 \(record.amount, specifier: "%.1f") 克")
                    .font(.subheadline.weight(.medium))
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AppPage2DayHeader: View {
    let group: AppPage2DayGroup

    var body: some View {
        HStack {
            Text(AppPage2Format.day.string(from: group.id))
                .font(.subheadline.weight(.semibold))

            Spacer()

            Text("\(group.records.count) 次 · \(AppPage2Format.amountText(group.records.reduce(0) { $0 + $1.amount }))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct AppPage2EmptyViewLocal: View {
    let hasAnyRecords: Bool
    let onClear: () -> Void
    let onAdd: () -> Void

    var body: some View {
        if hasAnyRecords {
            VStack(spacing: 12) {
                ContentUnavailableView(
                    "没有匹配的记录",
                    systemImage: "magnifyingglass",
                    description: Text("试试其他关键词或食物类型")
                )
                Button("清除筛选", action: onClear)
                    .buttonStyle(.bordered)
            }
        } else {
            ContentUnavailableView {
                Label("还没有喂食记录", systemImage: "clock.arrow.circlepath")
            } description: {
                Text("历史页会按天汇总每一次喂食，去添加第一条吧")
            } actions: {
                Button("添加第一条", action: onAdd)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

private struct AppPage2DetailViewLocal: View {
    @Environment(\.dismiss) private var dismiss

    let record: AppFeedRecord
    let petName: String
    let dailyTarget: Int

    var body: some View {
        NavigationStack {
            List {
                Section("喂食信息") {
                    LabeledContent("食物", value: record.foodType)
                    LabeledContent("时间", value: AppPage2Format.monthDayTime.string(from: record.date))
                    LabeledContent("数量", value: AppPage2Format.amountText(record.amount))
                    LabeledContent("备注", value: record.note.isEmpty ? "无" : record.note)
                }

                Section("宠物与目标") {
                    LabeledContent("宠物", value: petName.isEmpty ? "未设置" : petName)
                    LabeledContent("每日目标", value: "\(dailyTarget) 次")
                }
            }
            .navigationTitle("喂食详情")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct AppPage2AddViewLocal: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var foodType = ""
    @State private var amountText = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var showValidation = false

    private var amountValue: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var isAmountValid: Bool {
        guard let amountValue else { return false }
        return amountValue > 0 && amountValue <= 10000
    }

    private var canSave: Bool {
        !foodType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isAmountValid
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("喂食内容") {
                    TextField("食物类型（如鸡胸肉）", text: $foodType)
                    TextField("数量（克）", text: $amountText)
                        .keyboardType(.decimalPad)
                    TextField("备注（可选）", text: $note)
                }

                Section("时间") {
                    DatePicker(
                        "喂食时间",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                if showValidation {
                    Section {
                        Label(
                            "请填写食物类型，并输入 0-10000 之间的数量",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("添加记录")
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
                    .disabled(!canSave)
                }
            }
        }
    }

    func save() {
        guard let amount = amountValue, canSave else {
            showValidation = true
            return
        }

        let record = AppFeedRecord(
            id: UUID(),
            date: date,
            foodType: foodType.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        store.objectWillChange.send()
        store.feedingRecords.append(record)
        store.save()
        dismiss()
    }
}