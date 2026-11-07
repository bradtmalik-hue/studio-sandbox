import SwiftUI
import Foundation

struct AppPage1View: View {
    @EnvironmentObject private var store: AppStore
    @State private var filterCategory: String = "全部"
    @State private var activeSheet: AppPage1Sheet?

    var categories: [String] {
        var seen = Set<String>()
        for entry in store.todayEntries {
            seen.insert(entry.category)
        }
        return ["全部"] + seen.sorted()
    }

    private var filteredEntries: [AppWorkoutEntry] {
        if filterCategory == "全部" {
            return store.todayEntries
        }
        return store.todayEntries.filter { $0.category == filterCategory }
    }

    var totalMinutes: Int {
        store.todayEntries.reduce(0) { $0 + $1.durationMinutes }
    }

    private var totalCalories: Int {
        store.todayEntries.reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppPage1SummaryCard(
                    todayCount: store.todayEntries.count,
                    totalMinutes: totalMinutes,
                    totalCalories: totalCalories,
                    weeklyGoal: store.weeklyGoal,
                    weekRemaining: store.weekRemaining
                )

                HStack {
                    Text("筛选")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker("分类", selection: $filterCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)
                .padding(.bottom, 6)

                if filteredEntries.isEmpty {
                    AppPage1EmptyView(hasAnyToday: !store.todayEntries.isEmpty, onAdd: {
                        activeSheet = .add
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            ForEach(filteredEntries) { entry in
                                Button {
                                    activeSheet = .edit(entry)
                                } label: {
                                    AppPage1Row(entry: entry)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        delete(entry)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            Text("今天 · \(filteredEntries.count) 条记录")
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("今天练了什么")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        activeSheet = .add
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("添加训练")
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .add:
                    AppPage1EntryEditor(entry: nil) { newEntry in
                        save(newEntry)
                    }
                case .edit(let entry):
                    AppPage1EntryEditor(entry: entry) { updatedEntry in
                        save(updatedEntry)
                    }
                }
            }
        }
    }

    func delete(_ entry: AppWorkoutEntry) {
        withAnimation {
            store.entries.removeAll { $0.id == entry.id }
            store.save()
            validateFilter()
        }
    }

    func save(_ entry: AppWorkoutEntry) {
        withAnimation {
            if let index = store.entries.firstIndex(where: { $0.id == entry.id }) {
                store.entries[index] = entry
            } else {
                store.entries.append(entry)
            }
            store.save()
            validateFilter()
        }
    }

    private func validateFilter() {
        if filterCategory != "全部",
           !store.todayEntries.contains(where: { $0.category == filterCategory }) {
            filterCategory = "全部"
        }
    }
}

enum AppPage1Sheet: Identifiable {
    case add
    case edit(AppWorkoutEntry)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let entry):
            return entry.id.uuidString
        }
    }
}

struct AppPage1Row: View {
    let entry: AppWorkoutEntry

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(entry.category)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Label(Self.formatter.string(from: entry.date), systemImage: "clock")
                    Label("\(entry.durationMinutes)分钟", systemImage: "timer")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Label("\(entry.calories)千卡", systemImage: "flame")
                    Label("\(entry.sets)组 × \(entry.reps)次", systemImage: "repeat")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: entry.isOutdoor ? "sun.max.fill" : "house.fill")
                .foregroundStyle(entry.isOutdoor ? .orange : .blue)
                .font(.title3)
        }
        .padding(.vertical, 4)
    }
}

struct AppPage1SummaryCard: View {
    let todayCount: Int
    let totalMinutes: Int
    let totalCalories: Int
    let weeklyGoal: Int
    let weekRemaining: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("本周进度", systemImage: "target")
                    .font(.headline)
                Spacer()
                Text("目标 \(weeklyGoal) 次")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                AppPage1Metric(
                    value: "\(max(0, weekRemaining))",
                    unit: "次",
                    label: "还差",
                    tint: .orange
                )
                AppPage1Metric(
                    value: "\(todayCount)",
                    unit: "条",
                    label: "今日训练",
                    tint: .blue
                )
            }

            HStack(spacing: 10) {
                AppPage1Metric(
                    value: "\(totalMinutes)",
                    unit: "分钟",
                    label: "今日时长",
                    tint: .green
                )
                AppPage1Metric(
                    value: "\(totalCalories)",
                    unit: "千卡",
                    label: "今日消耗",
                    tint: .pink
                )
            }

            if weekRemaining <= 0 {
                Label("本周目标已达成", systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            } else {
                Text("再练 \(max(0, weekRemaining)) 次就能达成目标")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct AppPage1Metric: View {
    let value: String
    let unit: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.12))
        )
    }
}

struct AppPage1EmptyView: View {
    let hasAnyToday: Bool
    let onAdd: () -> Void

    var body: some View {
        if hasAnyToday {
            ContentUnavailableView {
                Label("没有符合筛选的记录", systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text("换个分类看看。")
            }
        } else {
            ContentUnavailableView {
                Label("今天还没练", systemImage: "figure.run")
            } description: {
                Text("记下今天的一组训练，清楚看到自己的进步。")
            } actions: {
                Button("添加第一条训练", action: onAdd)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct AppPage1EntryEditor: View {
    let entry: AppWorkoutEntry?
    let onSave: (AppWorkoutEntry) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var category: String
    @State private var date: Date
    @State private var durationMinutes: Int
    @State private var calories: Int
    @State private var reps: Int
    @State private var sets: Int
    @State private var isOutdoor: Bool
    @State private var notes: String
    @State private var showValidationError = false
    @State private var showCancelConfirmation = false

    init(entry: AppWorkoutEntry?, onSave: @escaping (AppWorkoutEntry) -> Void) {
        self.entry = entry
        self.onSave = onSave
        _title = State(initialValue: entry?.title ?? "")
        _category = State(initialValue: entry?.category ?? "力量训练")
        _date = State(initialValue: entry?.date ?? Date())
        _durationMinutes = State(initialValue: max(1, entry?.durationMinutes ?? 30))
        _calories = State(initialValue: max(0, entry?.calories ?? 0))
        _reps = State(initialValue: max(1, entry?.reps ?? 10))
        _sets = State(initialValue: max(1, entry?.sets ?? 3))
        _isOutdoor = State(initialValue: entry?.isOutdoor ?? false)
        _notes = State(initialValue: entry?.notes ?? "")
    }

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        durationMinutes > 0 &&
        durationMinutes <= 600 &&
        calories >= 0 &&
        calories <= 5000 &&
        reps > 0 &&
        reps <= 1000 &&
        sets > 0 &&
        sets <= 100
    }

    private var hasChanges: Bool {
        guard let original = entry else {
            return !title.isEmpty ||
                !category.isEmpty ||
                date != Date() ||
                durationMinutes != 30 ||
                calories != 0 ||
                reps != 10 ||
                sets != 3 ||
                isOutdoor ||
                !notes.isEmpty
        }
        return title != original.title ||
            category != original.category ||
            date != original.date ||
            durationMinutes != original.durationMinutes ||
            calories != original.calories ||
            reps != original.reps ||
            sets != original.sets ||
            isOutdoor != original.isOutdoor ||
            notes != original.notes
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("训练内容") {
                    TextField("标题，例如：卧推", text: $title)
                    TextField("分类，例如：力量训练", text: $category)
                }

                Section("训练量") {
                    Stepper("时长 \(durationMinutes) 分钟", value: $durationMinutes, in: 1...600)
                    Stepper("消耗 \(calories) 千卡", value: $calories, in: 0...5000)
                    Stepper("组数 \(sets)", value: $sets, in: 1...100)
                    Stepper("每组次数 \(reps)", value: $reps, in: 1...1000)
                }

                Section("日期与状态") {
                    DatePicker("训练时间", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Toggle("户外训练", isOn: $isOutdoor)
                }

                Section("备注") {
                    TextField("补充说明（可选）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(entry == nil ? "添加训练" : "编辑训练")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if hasChanges {
                            showCancelConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("请检查输入", isPresented: $showValidationError) {
                Button("好", role: .cancel) {}
            } message: {
                Text("标题和分类不能为空，时长、组数、次数必须大于 0，数值需在合理范围内。")
            }
            .alert("放弃修改？", isPresented: $showCancelConfirmation) {
                Button("继续编辑", role: .cancel) {}
                Button("放弃", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("未保存的修改会丢失。")
            }
        }
        .interactiveDismissDisabled(hasChanges)
    }

    func save() {
        guard isFormValid else {
            showValidationError = true
            return
        }
        let newEntry = AppWorkoutEntry(
            id: entry?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            durationMinutes: durationMinutes,
            calories: calories,
            reps: reps,
            sets: sets,
            isOutdoor: isOutdoor,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        onSave(newEntry)
        dismiss()
    }
}