import SwiftUI
import Foundation

struct AppPage1View: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingAddSheet = false
    @State private var editingTodo: AppTodoItem?
    @State private var searchText = ""
    @State private var filterCategory = "全部"

    var categories: [String] {
        Array(Set(store.todayTodos.map { $0.category })).sorted()
    }

    var filteredTodos: [AppTodoItem] {
        store.todayTodos
            .filter { item in
                (filterCategory == "全部" || item.category == filterCategory) &&
                (searchText.isEmpty ||
                 item.title.localizedCaseInsensitiveContains(searchText) ||
                 item.notes.localizedCaseInsensitiveContains(searchText))
            }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage1SummaryCard(
                        total: store.todayTotalCount,
                        remaining: store.todayRemainingCount,
                        completed: store.todayCompletedCount,
                        nextDue: filteredTodos.first?.dueDate
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("搜索待办", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    Picker("分类", selection: $filterCategory) {
                        Text("全部").tag("全部")
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    ForEach(filteredTodos) { item in
                        AppPage1TodoRow(
                            todo: item,
                            onToggle: { toggleCompletion(item) },
                            onTap: { editingTodo = item }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(item)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("今天")
            .overlay {
                if filteredTodos.isEmpty {
                    ContentUnavailableView {
                        Label("今天还没有待办", systemImage: "checklist")
                    } description: {
                        Text(searchText.isEmpty && filterCategory == "全部" ? "点下面按钮添加第一件事" : "换个筛选或搜索条件试试")
                    } actions: {
                        if searchText.isEmpty && filterCategory == "全部" {
                            Button("添加第一条") {
                                showingAddSheet = true
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("添加待办", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor, in: Capsule())
                        .foregroundStyle(.white)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(.thinMaterial)
            }
            .sheet(isPresented: $showingAddSheet) {
                AppPage1EditSheet(todo: nil)
                    .environmentObject(store)
            }
            .sheet(item: $editingTodo) { todo in
                AppPage1EditSheet(todo: todo)
                    .environmentObject(store)
            }
        }
    }

    private func toggleCompletion(_ item: AppTodoItem) {
        guard let index = store.todos.firstIndex(where: { $0.id == item.id }) else { return }
        store.todos[index].isCompleted = true
        store.todos[index].completedAt = Date()
        store.save()
    }

    func delete(_ item: AppTodoItem) {
        guard let index = store.todos.firstIndex(where: { $0.id == item.id }) else { return }
        store.todos.remove(at: index)
        store.save()
    }
}

private struct AppPage1SummaryCard: View {
    let total: Int
    let remaining: Int
    let completed: Int
    let nextDue: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                AppPage1Metric(value: total, label: "今日待办")
                Divider().frame(height: 44)
                AppPage1Metric(value: remaining, label: "待完成")
                Divider().frame(height: 44)
                AppPage1Metric(value: completed, label: "已完成")
            }
            if let nextDue {
                Label("下一项：\(AppPage1Format.string(from: nextDue))", systemImage: "clock")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}

private struct AppPage1Metric: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AppPage1PriorityBadge: View {
    let priority: AppPriority

    var body: some View {
        Text(priority.displayName)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.gray.opacity(0.15)))
    }
}

private struct AppPage1TodoRow: View {
    let todo: AppTodoItem
    let onToggle: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onToggle()
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(todo.isCompleted ? Color.green : Color.secondary)
            }
            .buttonStyle(.borderless)

            VStack(alignment: .leading, spacing: 5) {
                Text(todo.title)
                    .font(.headline)
                    .strikethrough(todo.isCompleted)
                    .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                HStack(spacing: 12) {
                    Label(AppPage1Format.string(from: todo.dueDate), systemImage: "calendar")
                    if !todo.category.isEmpty {
                        Label(todo.category, systemImage: "tag")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if !todo.notes.isEmpty {
                    Text(todo.notes)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 8)

            AppPage1PriorityBadge(priority: todo.priority)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

private struct AppPage1EditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    let todo: AppTodoItem?

    @State private var title: String
    @State private var notes: String
    @State private var dueDate: Date
    @State private var priority: AppPriority
    @State private var category: String
    @State private var showCancelConfirm = false

    init(todo: AppTodoItem?) {
        self.todo = todo
        _title = State(initialValue: todo?.title ?? "")
        _notes = State(initialValue: todo?.notes ?? "")
        _dueDate = State(initialValue: todo?.dueDate ?? Date())
        _priority = State(initialValue: todo?.priority ?? .medium)
        _category = State(initialValue: todo?.category ?? "日常")
    }

    private var isTitleValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isModified: Bool {
        guard let todo else {
            return !title.isEmpty ||
                   !notes.isEmpty ||
                   category != "日常" ||
                   dueDate != Date() ||
                   priority.rawValue != AppPriority.medium.rawValue
        }
        return title != todo.title ||
               notes != todo.notes ||
               dueDate != todo.dueDate ||
               priority.rawValue != todo.priority.rawValue ||
               category != todo.category
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("内容") {
                    TextField("准备做什么？", text: $title)
                    TextField("备注", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("时间与分类") {
                    DatePicker("截止时间", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    TextField("分类", text: $category)
                }

                Section("优先级") {
                    Picker("优先级", selection: $priority) {
                        ForEach([AppPriority.high, AppPriority.medium, AppPriority.low]) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if !isTitleValid && !title.isEmpty {
                    Section {
                        Label("标题不能为空", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle(todo == nil ? "新建待办" : "编辑待办")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if isModified {
                            showCancelConfirm = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!isTitleValid)
                }
            }
            .alert("放弃修改？", isPresented: $showCancelConfirm) {
                Button("继续编辑", role: .cancel) {}
                Button("放弃", role: .destructive) { dismiss() }
            } message: {
                Text("你有未保存的更改。")
            }
            .interactiveDismissDisabled(isModified)
        }
    }

    func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        if let existingTodo = todo,
           let index = store.todos.firstIndex(where: { $0.id == existingTodo.id }) {
            var updated = existingTodo
            updated.title = trimmedTitle
            updated.notes = notes
            updated.dueDate = dueDate
            updated.priority = priority
            updated.category = category
            store.todos[index] = updated
            store.save()
        } else {
            let newItem = AppTodoItem(
                id: UUID(),
                title: trimmedTitle,
                notes: notes,
                dueDate: dueDate,
                priority: priority,
                isCompleted: false,
                completedAt: nil,
                category: category,
                createdAt: Date()
            )
            store.todos.append(newItem)
            store.save()
        }
        dismiss()
    }
}

private enum AppPage1Format {
    static let dueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    static func string(from date: Date) -> String {
        dueDateFormatter.string(from: date)
    }
}