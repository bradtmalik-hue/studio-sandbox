import Foundation
import SwiftUI

struct AppPage2View: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var selectedEntry: AppWorkoutEntry?
    @State private var showingAddSheet = false

    private var allCategories: [String] {
        Array(Set(store.entries.map(\.category))).sorted()
    }

    var totalMinutes: Int {
        store.entries.reduce(0) { $0 + $1.durationMinutes }
    }

    private var filteredGroups: [AppWorkoutDayGroup] {
        store.groupedEntriesByDay.compactMap { group in
            let filtered = group.entries.filter { entry in
                let matchesCategory = selectedCategory == nil || entry.category == selectedCategory
                let query = searchText.trimmingCharacters(in: .whitespaces)
                let matchesSearch = query.isEmpty || entry.title.localizedCaseInsensitiveContains(query) || entry.notes.localizedCaseInsensitiveContains(query)
                return matchesCategory && matchesSearch
            }
            guard !filtered.isEmpty else { return nil }
            return AppWorkoutDayGroup(dayStart: group.dayStart, entries: filtered)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                summaryHeader
                searchAndFilter
                if store.entries.isEmpty {
                    ContentUnavailableView {
                        Label("还没有训练记录", systemImage: "figure.run.circle")
                    } description: {
                        Text("去第 1 页打卡，开始积累训练历史")
                    } actions: {
                        Button("添加第一条") {
                            showingAddSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if filteredGroups.isEmpty {
                    ContentUnavailableView {
                        Label("没有匹配记录", systemImage: "magnifyingglass")
                    } description: {
                        Text("换个关键词或分类试试")
                    }
                } else {
                    List {
                        ForEach(filteredGroups) { group in
                            Section {
                                ForEach(group.entries) { entry in
                                    Button {
                                        selectedEntry = entry
                                    } label: {
                                        AppPage2Row(entry: entry)
                                    }
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            store.delete(entry)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                HStack {
                                    Text(dayText(group.dayStart))
                                    Spacer()
                                    Text("\(group.entries.count) 个动作")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("历史")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $selectedEntry) { entry in
                AppPage2DetailView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingAddSheet) {
                AppPage2AddView()
                    .environmentObject(store)
            }
        }
    }

    private var summaryHeader: some View {
        HStack(spacing: 12) {
            AppPage2MetricCard(title: "总次数", value: "\(store.entries.count)", unit: "次")
            AppPage2MetricCard(title: "总时长", value: "\(totalMinutes)", unit: "分钟")
            AppPage2MetricCard(title: "平均时长", value: String(format: "%.0f", store.averageDuration), unit: "分钟")
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var searchAndFilter: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索训练名称或备注", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground).opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        selectedCategory = nil
                    } label: {
                        Text("全部")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedCategory == nil ? Color.accentColor : Color(.secondarySystemBackground))
                            .foregroundColor(selectedCategory == nil ? .white : .primary)
                            .clipShape(Capsule())
                    }

                    ForEach(allCategories, id: \.self) { category in
                        Button {
                            selectedCategory = selectedCategory == category ? nil : category
                        } label: {
                            Text(category)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedCategory == category ? Color.accentColor : Color(.secondarySystemBackground))
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 8)
    }

    private func dayText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEE"
        return formatter.string(from: date)
    }
}

private struct AppPage2MetricCard: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct AppPage2Row: View {
    let entry: AppWorkoutEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.isOutdoor ? "sun.max.fill" : "figure.strengthtraining.traditional")
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.headline)
                HStack(spacing: 6) {
                    Text(entry.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5), in: Capsule())
                    Text(timeText(entry.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.durationMinutes) 分钟")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text("\(entry.calories) 千卡")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

private struct AppPage2AddView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var category = "力量训练"
    @State private var date = Date()
    @State private var durationMinutes = 30
    @State private var calories = 200
    @State private var reps = 12
    @State private var sets = 3
    @State private var isOutdoor = false
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("训练内容") {
                    TextField("标题，例如 深蹲 5×5", text: $title)
                    TextField("分类", text: $category)
                    Picker("室内/室外", selection: $isOutdoor) {
                        Text("室内").tag(false)
                        Text("室外").tag(true)
                    }
                    DatePicker("日期", selection: $date)
                }

                Section("数据") {
                    Stepper("时长 \(durationMinutes) 分钟", value: $durationMinutes, in: 1...600)
                    Stepper("卡路里 \(calories) 千卡", value: $calories, in: 0...2000)
                    Stepper("组数 \(sets) 组", value: $sets, in: 1...50)
                    Stepper("次数 \(reps) 次", value: $reps, in: 1...500)
                }

                Section("备注") {
                    TextField("补充说明（可选）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("添加训练")
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
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || category.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    func save() {
        let entry = AppWorkoutEntry(
            id: UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            category: category.trimmingCharacters(in: .whitespaces),
            date: date,
            durationMinutes: durationMinutes,
            calories: calories,
            reps: reps,
            sets: sets,
            isOutdoor: isOutdoor,
            notes: notes
        )
        store.add(entry)
        dismiss()
    }
}

private struct AppPage2DetailView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let entry: AppWorkoutEntry

    @State private var title: String
    @State private var category: String
    @State private var date: Date
    @State private var durationMinutes: Int
    @State private var calories: Int
    @State private var reps: Int
    @State private var sets: Int
    @State private var isOutdoor: Bool
    @State private var notes: String

    init(entry: AppWorkoutEntry) {
        self.entry = entry
        _title = State(initialValue: entry.title)
        _category = State(initialValue: entry.category)
        _date = State(initialValue: entry.date)
        _durationMinutes = State(initialValue: entry.durationMinutes)
        _calories = State(initialValue: entry.calories)
        _reps = State(initialValue: entry.reps)
        _sets = State(initialValue: entry.sets)
        _isOutdoor = State(initialValue: entry.isOutdoor)
        _notes = State(initialValue: entry.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("训练内容") {
                    TextField("标题", text: $title)
                    TextField("分类", text: $category)
                    Picker("室内/室外", selection: $isOutdoor) {
                        Text("室内").tag(false)
                        Text("室外").tag(true)
                    }
                    DatePicker("日期", selection: $date)
                }

                Section("数据") {
                    Stepper("时长 \(durationMinutes) 分钟", value: $durationMinutes, in: 1...600)
                    Stepper("卡路里 \(calories) 千卡", value: $calories, in: 0...2000)
                    Stepper("组数 \(sets) 组", value: $sets, in: 1...50)
                    Stepper("次数 \(reps) 次", value: $reps, in: 1...500)
                }

                Section("备注") {
                    TextField("补充说明", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("训练详情")
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
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || category.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    func save() {
        let updated = AppWorkoutEntry(
            id: entry.id,
            title: title.trimmingCharacters(in: .whitespaces),
            category: category.trimmingCharacters(in: .whitespaces),
            date: date,
            durationMinutes: durationMinutes,
            calories: calories,
            reps: reps,
            sets: sets,
            isOutdoor: isOutdoor,
            notes: notes
        )
        store.update(updated)
        dismiss()
    }
}

extension AppStore {
    func add(_ entry: AppWorkoutEntry) {
        entries.append(entry)
    }

    func delete(_ entry: AppWorkoutEntry) {
        entries.removeAll { $0.id == entry.id }
    }

    func update(_ entry: AppWorkoutEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        }
    }
}