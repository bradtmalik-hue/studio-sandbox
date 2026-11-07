import SwiftUI
import Combine

struct AppPage1View: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText: String = ""
    @State private var filter: AppPage1Filter = .all
    @State private var editorMode: AppPage1EditorMode?

    private static let rowTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    private static let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private var todayRecords: [AppFeedRecord] {
        store.records
            .filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date > $1.date }
    }

    var filteredRecords: [AppFeedRecord] {
        todayRecords.filter { record in
            let matchesSearch = searchText.isEmpty
                || record.foodType.localizedCaseInsensitiveContains(searchText)
                || record.note.localizedCaseInsensitiveContains(searchText)

            guard matchesSearch else { return false }

            switch filter {
            case .all:
                return true
            case .staple:
                return record.foodType.contains("主食")
                    || record.foodType.contains("干粮")
                    || record.foodType.contains("粮")
            case .snack:
                return record.foodType.contains("零食")
                    || record.foodType.contains("猫条")
                    || record.foodType.contains("罐")
                    || record.foodType.contains("湿粮")
            case .other:
                return !(record.foodType.contains("主食")
                    || record.foodType.contains("干粮")
                    || record.foodType.contains("粮")
                    || record.foodType.contains("零食")
                    || record.foodType.contains("猫条")
                    || record.foodType.contains("罐")
                    || record.foodType.contains("湿粮"))
            }
        }
    }

    var body: some View {
        ZStack {
            List {
                if !todayRecords.isEmpty {
                    AppPage1SummaryCard(
                        count: todayRecords.count,
                        totalAmount: todayRecords.reduce(0) { $0 + $1.amount },
                        recentDate: todayRecords.first?.date,
                        target: store.settings.dailyTarget
                    )
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowSeparator(.hidden)
                }

                Section {
                    ForEach(filteredRecords) { record in
                        Button {
                            editorMode = .edit(record)
                        } label: {
                            AppPage1Row(
                                record: record,
                                timeText: Self.rowTimeFormatter.string(from: record.date)
                            )
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
                    if !filteredRecords.isEmpty {
                        Text("今日记录")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.bottom, 96, for: .scrollContent)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索食物或备注")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("筛选", selection: $filter) {
                        ForEach(AppPage1Filter.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 280)
                }
            }

            if filteredRecords.isEmpty {
                ContentUnavailableView {
                    Label(
                        todayRecords.isEmpty ? "今天还没有喂食记录" : "没有匹配的记录",
                        systemImage: todayRecords.isEmpty ? "pawprint.fill" : "magnifyingglass"
                    )
                } description: {
                    Text(todayRecords.isEmpty ? "点下面“记一笔”，给毛孩子记下第一顿" : "换个关键词或筛选条件试试")
                } actions: {
                    if todayRecords.isEmpty {
                        Button("添加第一条") {
                            editorMode = .new
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle("今天")
        .safeAreaInset(edge: .bottom) {
            Button {
                editorMode = .new
            } label: {
                Label("记一笔", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial)
        }
        .sheet(item: $editorMode) { mode in
            NavigationStack {
                AppPage1EditorView(mode: mode)
                    .environmentObject(store)
            }
        }
    }

    func delete(_ record: AppFeedRecord) {
        withAnimation {
            store.records.removeAll { $0.id == record.id }
            store.save()
        }
    }
}

enum AppPage1Filter: String, CaseIterable, Identifiable {
    case all = "全部"
    case staple = "主食"
    case snack = "零食"
    case other = "其他"

    var id: String { rawValue }
}

enum AppPage1EditorMode: Identifiable {
    case new
    case edit(AppFeedRecord)

    var id: UUID {
        switch self {
        case .new:
            return UUID()
        case .edit(let record):
            return record.id
        }
    }
}

struct AppPage1SummaryCard: View {
    let count: Int
    let totalAmount: Double
    let recentDate: Date?
    let target: Int

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日喂食")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(count) 次")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("目标")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(target) 次")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }

            Divider()

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("合计")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalAmount, specifier: "%.1f") 克")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("最近一次")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let recentDate = recentDate {
                        Text(Self.timeFormatter.string(from: recentDate))
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                    } else {
                        Text("—")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "fork.knife")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }
}

struct AppPage1Row: View {
    let record: AppFeedRecord
    let timeText: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 46, height: 46)

                Image(systemName: symbolName(for: record.foodType))
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(record.foodType.isEmpty ? "未命名食物" : record.foodType)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text("\(record.amount, specifier: "%.1f") 克")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("·")
                        .foregroundColor(.secondary)

                    Text(timeText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func symbolName(for foodType: String) -> String {
        if foodType.contains("主食") || foodType.contains("干粮") || foodType.contains("粮") {
            return "circle.hexagongrid.fill"
        } else if foodType.contains("零食") || foodType.contains("猫条") || foodType.contains("罐") || foodType.contains("湿粮") {
            return "heart.fill"
        } else {
            return "pawprint.fill"
        }
    }
}

struct AppPage1EditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore

    let mode: AppPage1EditorMode

    @State private var foodType: String
    @State private var amountText: String
    @State private var note: String
    @State private var date: Date
    @State private var confirmed: Bool = false
    @State private var showDiscardAlert: Bool = false
    @State private var amountMessage: String?

    private var originalRecord: AppFeedRecord? {
        if case .edit(let record) = mode {
            return record
        }
        return nil
    }

    init(mode: AppPage1EditorMode) {
        self.mode = mode
        switch mode {
        case .new:
            _foodType = State(initialValue: "")
            _amountText = State(initialValue: "")
            _note = State(initialValue: "")
            _date = State(initialValue: Date())
        case .edit(let record):
            _foodType = State(initialValue: record.foodType)
            _amountText = State(initialValue: String(format: "%.1f", record.amount))
            _note = State(initialValue: record.note)
            _date = State(initialValue: record.date)
        }
    }

    private var trimmedFoodType: String {
        foodType.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var isValid: Bool {
        guard !trimmedFoodType.isEmpty else { return false }
        guard let amount = parsedAmount, amount > 0 else { return false }
        return confirmed && amountMessage == nil
    }

    private var hasUnsavedChanges: Bool {
        let base = originalRecord
        let currentAmount = parsedAmount ?? 0
        let originalAmount = base?.amount ?? 0

        return trimmedFoodType != (base?.foodType ?? "")
            || currentAmount != originalAmount
            || note != (base?.note ?? "")
            || !Calendar.current.isDate(date, inSameDayAs: base?.date ?? Date())
            || (base == nil && (!trimmedFoodType.isEmpty || !amountText.isEmpty || !note.isEmpty))
    }

    var body: some View {
        Form {
            Section {
                TextField("食物名称，例如：渴望鸡猫粮", text: $foodType)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            } header: {
                Text("基础信息")
            } footer: {
                Text("请填写主食、零食或罐头等具体名称。")
            }

            Section {
                TextField("重量（克）", text: $amountText)
                    .keyboardType(.decimalPad)
                    .onChange(of: amountText) { newValue in
                        guard !newValue.isEmpty else {
                            amountMessage = nil
                            return
                        }
                        if let value = Double(newValue.replacingOccurrences(of: ",", with: ".")), value > 0 {
                            amountMessage = nil
                        } else {
                            amountMessage = "请输入大于 0 的数值。"
                        }
                    }

                if let message = amountMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                DatePicker("喂食时间", selection: $date)
            } header: {
                Text("喂食信息")
            }

            Section {
                TextField("备注，例如：胃口不错、剩了一点", text: $note, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text("备注")
            }

            Section {
                Toggle("我确认这份记录无误", isOn: $confirmed)
            }

            if isValid {
                Section {
                    Label("保存后会立即更新今天列表", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(originalRecord == nil ? "新增加喂食记录" : "编辑喂食记录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    if hasUnsavedChanges {
                        showDiscardAlert = true
                    } else {
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    save()
                }
                .disabled(!isValid)
            }
        }
        .alert("放弃更改？", isPresented: $showDiscardAlert) {
            Button("继续编辑", role: .cancel) { }
            Button("放弃更改", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("当前编辑内容尚未保存。")
        }
    }

    private func save() {
        let trimmedFood = trimmedFoodType
        guard let amount = parsedAmount, amount > 0, !trimmedFood.isEmpty else { return }

        if let original = originalRecord {
            let updatedRecord = AppFeedRecord(
                id: original.id,
                date: date,
                foodType: trimmedFood,
                amount: amount,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                petName: original.petName,
                dailyTarget: original.dailyTarget
            )
            if let index = store.records.firstIndex(where: { $0.id == original.id }) {
                store.records[index] = updatedRecord
            }
        } else {
            let newRecord = AppFeedRecord(
                id: UUID(),
                date: date,
                foodType: trimmedFood,
                amount: amount,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                petName: store.settings.petName,
                dailyTarget: store.settings.dailyTarget
            )
            store.records.append(newRecord)
        }
        store.save()
        dismiss()
    }
}