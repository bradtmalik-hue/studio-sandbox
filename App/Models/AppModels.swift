import Foundation
import Combine

struct AppExpense: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var amount: Double
    var paidBy: String
    var participants: [String]
    var date: Date
    var note: String
}

struct AppSettings: Codable, Equatable {
    var defaultParticipantCount: Int
    var defaultPayer: String
    var currencyCode: String

    static let defaultCurrency = "CNY"
}

struct AppBalance: Identifiable {
    var id: String { name }
    var name: String
    var amount: Double
}

struct AppTransfer: Identifiable {
    var id: String { "\(from)-\(to)" }
    var from: String
    var to: String
    var amount: Double
}

struct AppPersistedData: Codable {
    var expenses: [AppExpense]
    var settings: AppSettings
}

final class AppStore: ObservableObject {
    @Published var expenses: [AppExpense] = []
    @Published var settings = AppSettings(defaultParticipantCount: 4, defaultPayer: "我", currencyCode: AppSettings.defaultCurrency)

    private let fileURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("SplitBillData.json")
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(AppPersistedData.self, from: data) else {
            return
        }
        expenses = decoded.expenses
        settings = decoded.settings
    }

    func save() {
        do {
            let container = AppPersistedData(expenses: expenses, settings: settings)
            let data = try JSONEncoder().encode(container)
            try data.write(to: fileURL)
        } catch {
        }
    }

    func addExpense(_ expense: AppExpense) {
        expenses.append(expense)
        save()
    }

    func deleteExpense(id: UUID) {
        expenses.removeAll { $0.id == id }
        save()
    }

    func updateExpense(_ expense: AppExpense) {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        expenses[index] = expense
        save()
    }

    var totalAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var latestExpenseDate: Date? {
        expenses.map(\.date).max()
    }

    func balances() -> [AppBalance] {
        var dict: [String: Double] = [:]
        for expense in expenses {
            let participantCount = max(expense.participants.count, 1)
            let share = expense.amount / Double(participantCount)
            dict[expense.paidBy, default: 0] += expense.amount - share
            for participant in expense.participants where participant != expense.paidBy {
                dict[participant, default: 0] -= share
            }
        }
        return dict
            .map { AppBalance(name: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    func transfers() -> [AppTransfer] {
        let balances = balances()
        var debtors = balances
            .filter { $0.amount < 0 }
            .map { (name: $0.name, amount: -$0.amount) }
        var creditors = balances
            .filter { $0.amount > 0 }
            .map { (name: $0.name, amount: $0.amount) }

        var result: [AppTransfer] = []
        var i = 0
        var j = 0

        while i < debtors.count && j < creditors.count {
            let payment = min(debtors[i].amount, creditors[j].amount)
            if payment > 0.0001 {
                result.append(AppTransfer(from: debtors[i].name, to: creditors[j].name, amount: payment))
            }
            debtors[i].amount -= payment
            creditors[j].amount -= payment

            if debtors[i].amount < 0.0001 {
                i += 1
            }
            if creditors[j].amount < 0.0001 {
                j += 1
            }
        }

        return result
    }
}

enum DemoSeed {
    static func apply(into store: AppStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }

        let calendar = Calendar.current
        let now = Date()

        func date(daysAgo: Int, hour: Int, minute: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }

        let samples: [AppExpense] = [
            AppExpense(id: UUID(), title: "川味火锅聚餐", amount: 428.50, paidBy: "陈晨", participants: ["陈晨", "李娜", "王强", "赵敏"], date: date(daysAgo: 1, hour: 19, minute: 30), note: "部门小聚"),
            AppExpense(id: UUID(), title: "周末桌游吧", amount: 168.00, paidBy: "李娜", participants: ["陈晨", "李娜", "王强"], date: date(daysAgo: 3, hour: 14, minute: 10), note: "三国杀包间"),
            AppExpense(id: UUID(), title: "生日蛋糕", amount: 238.00, paidBy: "王强", participants: ["陈晨", "李娜", "王强", "赵敏", "刘洋"], date: date(daysAgo: 5, hour: 20, minute: 0), note: "给赵敏庆生"),
            AppExpense(id: UUID(), title: "烧烤夜宵", amount: 312.40, paidBy: "刘洋", participants: ["刘洋", "陈晨", "李娜", "赵敏"], date: date(daysAgo: 7, hour: 23, minute: 15), note: "路边摊"),
            AppExpense(id: UUID(), title: "KTV 欢唱", amount: 456.00, paidBy: "赵敏", participants: ["赵敏", "陈晨", "李娜", "王强", "刘洋"], date: date(daysAgo: 10, hour: 21, minute: 0), note: "周末包夜"),
            AppExpense(id: UUID(), title: "团建午餐", amount: 680.00, paidBy: "陈晨", participants: ["陈晨", "李娜", "王强", "赵敏", "刘洋", "孙悦"], date: date(daysAgo: 12, hour: 12, minute: 20), note: "团建日料"),
            AppExpense(id: UUID(), title: "咖啡下午茶", amount: 96.50, paidBy: "孙悦", participants: ["孙悦", "陈晨", "李娜"], date: date(daysAgo: 15, hour: 15, minute: 45), note: "拿铁+蛋糕"),
            AppExpense(id: UUID(), title: "羽毛球场地费", amount: 120.00, paidBy: "王强", participants: ["王强", "陈晨", "李娜", "赵敏"], date: date(daysAgo: 18, hour: 18, minute: 30), note: "两小时"),
            AppExpense(id: UUID(), title: "外卖午餐", amount: 89.90, paidBy: "李娜", participants: ["李娜", "陈晨", "王强"], date: date(daysAgo: 20, hour: 12, minute: 5), note: "麻辣香锅"),
            AppExpense(id: UUID(), title: "电影票", amount: 160.00, paidBy: "陈晨", participants: ["陈晨", "李娜", "王强", "赵敏"], date: date(daysAgo: 22, hour: 19, minute: 40), note: "IMAX"),
            AppExpense(id: UUID(), title: "打车拼车", amount: 45.60, paidBy: "刘洋", participants: ["刘洋", "陈晨", "李娜"], date: date(daysAgo: 25, hour: 22, minute: 10), note: "回家"),
            AppExpense(id: UUID(), title: "野餐食材", amount: 278.30, paidBy: "赵敏", participants: ["赵敏", "陈晨", "李娜", "王强", "刘洋"], date: date(daysAgo: 28, hour: 11, minute: 30), note: "公园野餐")
        ]

        store.expenses = samples
        store.settings.defaultParticipantCount = 4
        store.settings.defaultPayer = "陈晨"
        store.save()
    }
}