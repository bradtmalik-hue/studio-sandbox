import Foundation
import Combine
import SwiftUI

enum AppPriority: String, Codable, CaseIterable, Identifiable {
    case high
    case medium
    case low

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .high: return "高"
        case .medium: return "中"
        case .low: return "低"
        }
    }

    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

struct AppTodoItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var notes: String
    var dueDate: Date
    var priority: AppPriority
    var isCompleted: Bool
    var completedAt: Date?
    var category: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        dueDate: Date = Date(),
        priority: AppPriority = .medium,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        category: String = "默认",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.category = category
        self.createdAt = createdAt
    }

    var isOverdue: Bool {
        !isCompleted && dueDate < Date()
    }

    var priorityDisplayName: String {
        priority.displayName
    }
}

struct AppSettings: Codable, Equatable {
    var maxDailyTodos: Int
    var reminderEnabled: Bool
    var reminderTime: Date
    var defaultCategory: String

    init(
        maxDailyTodos: Int = 5,
        reminderEnabled: Bool = false,
        reminderTime: Date = Date(),
        defaultCategory: String = "默认"
    ) {
        self.maxDailyTodos = maxDailyTodos
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.defaultCategory = defaultCategory
    }
}

final class AppStore: ObservableObject {
    @Published var todos: [AppTodoItem] = []
    @Published var settings: AppSettings = AppSettings(maxDailyTodos: 0, reminderEnabled: false, reminderTime: Date(), defaultCategory: "") {
        didSet { saveSettings() }
    }

    private let todosURL: URL
    private let settingsURL: URL

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        todosURL = docs.appendingPathComponent("todos.json")
        settingsURL = docs.appendingPathComponent("settings.json")
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }

    var todayTodos: [AppTodoItem] {
        let calendar = Calendar.current
        return todos
            .filter { !$0.isCompleted && calendar.isDateInToday($0.dueDate) }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var completedTodos: [AppTodoItem] {
        todos
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? $0.dueDate) > ($1.completedAt ?? $1.dueDate) }
    }

    var todayTotalCount: Int {
        let calendar = Calendar.current
        return todos.filter { calendar.isDateInToday($0.dueDate) }.count
    }

    var todayRemainingCount: Int {
        todayTodos.count
    }

    var todayCompletedCount: Int {
        let calendar = Calendar.current
        return todos.filter { $0.isCompleted && calendar.isDateInToday($0.completedAt ?? $0.dueDate) }.count
    }

    var allCategories: [String] {
        Array(Set(todos.map { $0.category })).sorted()
    }

    func canAddMoreToday() -> Bool {
        todayRemainingCount < settings.maxDailyTodos
    }

    func add(_ item: AppTodoItem) {
        todos.append(item)
        saveTodos()
    }

    func delete(_ item: AppTodoItem) {
        todos.removeAll { $0.id == item.id }
        saveTodos()
    }

    func delete(at offsets: IndexSet) {
        todos.remove(atOffsets: offsets)
        saveTodos()
    }

    func toggleComplete(_ item: AppTodoItem) {
        guard let index = todos.firstIndex(where: { $0.id == item.id }) else { return }
        todos[index].isCompleted.toggle()
        if todos[index].isCompleted {
            todos[index].completedAt = Date()
        } else {
            todos[index].completedAt = nil
        }
        saveTodos()
    }

    func update(_ item: AppTodoItem) {
        guard let index = todos.firstIndex(where: { $0.id == item.id }) else { return }
        todos[index] = item
        saveTodos()
    }

    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
        saveSettings()
    }

    func bindingForMaxDailyTodos() -> Binding<Int> {
        Binding(
            get: { self.settings.maxDailyTodos },
            set: { self.settings.maxDailyTodos = $0 }
        )
    }

    func bindingForReminderEnabled() -> Binding<Bool> {
        Binding(
            get: { self.settings.reminderEnabled },
            set: { self.settings.reminderEnabled = $0 }
        )
    }

    func bindingForReminderTime() -> Binding<Date> {
        Binding(
            get: { self.settings.reminderTime },
            set: { self.settings.reminderTime = $0 }
        )
    }

    func bindingForDefaultCategory() -> Binding<String> {
        Binding(
            get: { self.settings.defaultCategory },
            set: { self.settings.defaultCategory = $0 }
        )
    }

    private func load() {
        if let data = try? Data(contentsOf: todosURL),
           let decoded = try? decoder.decode([AppTodoItem].self, from: data) {
            todos = decoded
        } else {
            todos = []
        }

        if let data = try? Data(contentsOf: settingsURL),
           let decoded = try? decoder.decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = AppSettings(maxDailyTodos: 0, reminderEnabled: false, reminderTime: Date(), defaultCategory: "")
        }
    }

    func save() {
        saveTodos()
        saveSettings()
    }

    private func saveTodos() {
        do {
            let data = try encoder.encode(todos)
            try data.write(to: todosURL)
        } catch {
        }
    }

    func saveSettings() {
        do {
            let data = try encoder.encode(settings)
            try data.write(to: settingsURL)
        } catch {
        }
    }
}

enum DemoSeed {
    static func apply(into store: AppStore) {
        let calendar = Calendar.current
        let now = Date()
        var items: [AppTodoItem] = []

        let titles = [
            "写周报",
            "回复邮件",
            "整理桌面",
            "买牛奶",
            "健身30分钟",
            "读20页书",
            "打电话给妈妈",
            "计划周末行程",
            "学习SwiftUI",
            "整理相册"
        ]
        let categories = ["工作", "生活", "健康", "学习", "家庭"]
        let priorities: [AppPriority] = [.high, .medium, .low]

        for i in 0..<10 {
            let isCompleted = i % 3 == 0
            let dayOffset = i < 5 ? 0 : -1
            let dueDate = calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
            let completedAt = isCompleted ? calendar.date(byAdding: .hour, value: -i, to: now) : nil
            let createdAt = calendar.date(byAdding: .day, value: -i, to: now) ?? now

            let item = AppTodoItem(id: UUID(), title: titles[i % titles.count], notes: "示例备注 \(i + 1)", dueDate: dueDate, priority: priorities[i % priorities.count], isCompleted: isCompleted, completedAt: completedAt, category: categories[i % categories.count], createdAt: createdAt)
            items.append(item)
        }

        items.sort { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            return lhs.dueDate < rhs.dueDate
        }

        store.todos = items
        store.settings = AppSettings(
            maxDailyTodos: 5,
            reminderEnabled: true,
            reminderTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now,
            defaultCategory: "默认"
        )
        store.save()
    }
}