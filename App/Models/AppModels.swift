import Foundation
import Combine

struct AppRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var amount: Double
    var category: String
    var note: String
    var date: Date
    var isExpense: Bool

    var isIncome: Bool {
        !isExpense
    }

    var amountText: String {
        String(format: "%.2f", amount)
    }

    var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

enum AppRecordCategory {
    static let expense = ["早餐", "午餐", "晚餐", "购物", "交通", "娱乐", "医疗", "住房", "其他"]
    static let income = ["工资", "兼职", "奖金", "理财", "其他"]
    static let all = expense + income
}

class AppStore: ObservableObject {
    @Published var records: [AppRecord] = []

    private let fileName = "app_records.json"

    init() {
        load()
    }

    private var fileURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent(fileName)
    }

    func load() {
        let url = fileURL
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([AppRecord].self, from: data) else {
            records = []
            return
        }
        records = decoded.sorted { $0.date > $1.date }
    }

    func save() {
        let url = fileURL
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: url)
    }

    func add(_ record: AppRecord) {
        records.append(record)
        records.sort { $0.date > $1.date }
        save()
    }

    func update(_ record: AppRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
            records.sort { $0.date > $1.date }
            save()
        }
    }

    func delete(_ record: AppRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        save()
    }

    var totalIncome: Double {
        records.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
    }

    var totalExpense: Double {
        records.filter { $0.isExpense }.reduce(0) { $0 + $1.amount }
    }

    var balance: Double {
        totalIncome - totalExpense
    }

    func records(for category: String) -> [AppRecord] {
        records.filter { $0.category == category }
    }

    func total(for category: String) -> Double {
        records(for: category).reduce(0) { $0 + $1.amount }
    }

    func records(forMonth date: Date) -> [AppRecord] {
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
    }

    func totalIncome(forMonth date: Date) -> Double {
        records(forMonth: date).filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
    }

    func totalExpense(forMonth date: Date) -> Double {
        records(forMonth: date).filter { $0.isExpense }.reduce(0) { $0 + $1.amount }
    }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
        let store = AppStore()
        guard store.records.isEmpty else { return }

        let calendar = Calendar.current
        let today = Date()

        var samples: [AppRecord] = [
            AppRecord(amount: 25.5, category: "早餐", note: "豆浆油条", date: today, isExpense: true),
            AppRecord(amount: 45.0, category: "午餐", note: "工作餐", date: today, isExpense: true),
            AppRecord(amount: 365.0, category: "购物", note: "超市采购", date: calendar.date(byAdding: .day, value: -1, to: today)!, isExpense: true),
            AppRecord(amount: 150.0, category: "交通", note: "加油", date: calendar.date(byAdding: .day, value: -2, to: today)!, isExpense: true),
            AppRecord(amount: 5200.0, category: "工资", note: "三月工资", date: calendar.date(byAdding: .day, value: -3, to: today)!, isExpense: false),
            AppRecord(amount: 88.0, category: "娱乐", note: "电影票", date: calendar.date(byAdding: .day, value: -4, to: today)!, isExpense: true),
            AppRecord(amount: 200.0, category: "餐饮", note: "朋友聚餐", date: calendar.date(byAdding: .day, value: -5, to: today)!, isExpense: true),
            AppRecord(amount: 120.0, category: "购物", note: "日用品", date: calendar.date(byAdding: .day, value: -6, to: today)!, isExpense: true),
            AppRecord(amount: 80.0, category: "医疗", note: "药店买药", date: calendar.date(byAdding: .day, value: -7, to: today)!, isExpense: true),
            AppRecord(amount: 2000.0, category: "兼职", note: "周末兼职", date: calendar.date(byAdding: .day, value: -8, to: today)!, isExpense: false)
        ]

        samples.sort { $0.date > $1.date }
        store.records = samples
        store.save()
    }
}