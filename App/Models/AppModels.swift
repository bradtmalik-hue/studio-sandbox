import Foundation
import Combine

enum AppCategory: String, Codable, CaseIterable, Identifiable {
    case dining = "餐饮"
    case transport = "交通"
    case shopping = "购物"
    case other = "其它"

    var id: String { rawValue }
}

struct AppExpense: Identifiable, Codable, Equatable {
    var id: UUID
    var amount: Double
    var category: AppCategory
    var note: String
    var date: Date

    init(id: UUID = UUID(), amount: Double, category: AppCategory, note: String, date: Date = Date()) {
        self.id = id
        self.amount = amount
        self.category = category
        self.note = note
        self.date = date
    }
}

struct AppExpenseStoreData: Codable {
    var expenses: [AppExpense]
    var monthlyBudget: Double
}

final class AppStore: ObservableObject {
    @Published var expenses: [AppExpense] = []
    @Published var monthlyBudget: Double = 3000

    private let fileName = "expenses.json"
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }

    init() {
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply()
        }
    }

    var todayExpenses: [AppExpense] {
        expenses.filter { Calendar.current.isDateInToday($0.date) }
    }

    var todayTotal: Double {
        todayExpenses.reduce(0) { $0 + $1.amount }
    }

    var isOverBudget: Bool {
        todayTotal > monthlyBudget
    }

    var monthExpenses: [AppExpense] {
        expenses.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }

    var monthTotal: Double {
        monthExpenses.reduce(0) { $0 + $1.amount }
    }

    func total(for category: AppCategory, on date: Date = Date()) -> Double {
        expenses.filter { $0.category == category && Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.amount }
    }

    func addExpense(_ expense: AppExpense) {
        expenses.append(expense)
        save()
    }

    func updateExpense(_ expense: AppExpense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            save()
        }
    }

    func deleteExpense(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
        save()
    }

    func deleteExpense(_ expense: AppExpense) {
        expenses.removeAll { $0.id == expense.id }
        save()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(AppExpenseStoreData.self, from: data) {
            expenses = decoded.expenses
            monthlyBudget = decoded.monthlyBudget
        }
    }

    func save() {
        let storeData = AppExpenseStoreData(expenses: expenses, monthlyBudget: monthlyBudget)
        if let data = try? JSONEncoder().encode(storeData) {
            try? data.write(to: fileURL)
        }
    }
}

enum AppFormat {
    static let zhDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    static func date(_ date: Date) -> String {
        zhDateFormatter.string(from: date)
    }

    static func currency(_ amount: Double) -> String {
        String(format: "¥%.2f", amount)
    }
}

enum DemoSeed {
    static func apply() {
    }

    static func apply(into store: AppStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }
        let calendar = Calendar.current
        let now = Date()
        let categories = AppCategory.allCases
        let notes = ["早餐", "午餐", "咖啡", "地铁", "打车", "日用品", "超市", "外卖", "电影", "礼物", "充电", "晚餐"]
        var seeded: [AppExpense] = []
        for index in 0..<12 {
            let category = categories[index % categories.count]
            let amount = Double(15 + index * 8) + Double(index % 5) * 0.5
            let date: Date
            if index < 5 {
                date = now
            } else {
                date = calendar.date(byAdding: .day, value: -(index - 2), to: now) ?? now
            }
            let note = notes[index % notes.count]
            seeded.append(AppExpense(id: UUID(), amount: amount, category: category, note: note, date: date))
        }
        store.expenses = seeded
        store.monthlyBudget = 3000
        store.save()
    }
}