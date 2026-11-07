import Foundation
import Combine

struct AppExpense: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var amount: Double
    var payer: String
    var date: Date
    var participantCount: Int
    var participants: [String]
    var note: String
    var category: String

    init(
        id: UUID = UUID(),
        title: String = "",
        amount: Double = 0,
        payer: String = "",
        date: Date = Date(),
        participantCount: Int = 0,
        participants: [String] = [],
        note: String = "",
        category: String = "其他"
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.payer = payer
        self.date = date
        self.participantCount = participantCount
        self.participants = participants
        self.note = note
        self.category = category
    }

    var perPersonAmount: Double {
        participantCount > 0 ? amount / Double(participantCount) : 0
    }

    var otherParticipants: [String] {
        participants.filter { $0 != payer }
    }
}

final class AppStore: ObservableObject {
    @Published var expenses: [AppExpense]
    @Published var defaultParticipantCount: Int

    static let dataFileURL: URL = {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("expenses.json")
    }()

    init() {
        self.expenses = []
        self.defaultParticipantCount = 4
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }

    var sortedExpenses: [AppExpense] {
        expenses.sorted { $0.date > $1.date }
    }

    var totalAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var averagePerExpense: Double {
        expenses.isEmpty ? 0 : totalAmount / Double(expenses.count)
    }

    func add(_ expense: AppExpense) {
        expenses.append(expense)
        save()
    }

    func add(expense: AppExpense) {
        add(expense)
    }

    func update(_ expense: AppExpense) {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        expenses[index] = expense
        save()
    }

    func delete(_ expense: AppExpense) {
        expenses.removeAll { $0.id == expense.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
        save()
    }

    func delete(id: UUID) {
        expenses.removeAll { $0.id == id }
        save()
    }

    func clearAll() {
        expenses.removeAll()
        save()
    }

    func save() {
        let snapshot = AppStoreSnapshot(expenses: expenses, defaultParticipantCount: defaultParticipantCount)
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: Self.dataFileURL)
        } catch {
        }
    }

    private func load() {
        let url = Self.dataFileURL
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(AppStoreSnapshot.self, from: data) else {
            return
        }
        expenses = snapshot.expenses
        defaultParticipantCount = snapshot.defaultParticipantCount
    }
}

private struct AppStoreSnapshot: Codable {
    var expenses: [AppExpense]
    var defaultParticipantCount: Int
}

enum DemoSeed {
    static func apply(into store: AppStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }

        let calendar = Calendar.current
        let now = Date()
        func makeDate(daysAgo: Int, hour: Int, minute: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? now
        }

        let demoExpenses: [AppExpense] = [
            AppExpense(id: UUID(), title: "周五火锅聚餐", amount: 420, payer: "张伟", date: makeDate(daysAgo: 0, hour: 19, minute: 30), participantCount: 4, participants: ["张伟", "李娜", "王芳", "赵磊"], note: "含锅底和饮料", category: "餐饮"),
            AppExpense(id: UUID(), title: "打车去机场", amount: 95, payer: "李娜", date: makeDate(daysAgo: 1, hour: 8, minute: 15), participantCount: 3, participants: ["李娜", "张伟", "王芳"], note: "机场高速费另算", category: "交通"),
            AppExpense(id: UUID(), title: "民宿两晚", amount: 880, payer: "王芳", date: makeDate(daysAgo: 2, hour: 14, minute: 0), participantCount: 4, participants: ["王芳", "张伟", "李娜", "赵磊"], note: "整栋预订", category: "住宿"),
            AppExpense(id: UUID(), title: "桌游吧包间", amount: 240, payer: "赵磊", date: makeDate(daysAgo: 3, hour: 20, minute: 0), participantCount: 5, participants: ["赵磊", "张伟", "李娜", "王芳", "刘洋"], note: "四小时畅玩", category: "娱乐"),
            AppExpense(id: UUID(), title: "露营食材采购", amount: 318.5, payer: "张伟", date: makeDate(daysAgo: 4, hour: 17, minute: 45), participantCount: 5, participants: ["张伟", "李娜", "王芳", "赵磊", "刘洋"], note: "含烧烤工具", category: "餐饮"),
            AppExpense(id: UUID(), title: "高铁票改签费", amount: 60, payer: "李娜", date: makeDate(daysAgo: 5, hour: 9, minute: 20), participantCount: 3, participants: ["李娜", "张伟", "王芳"], note: "临时改签", category: "交通"),
            AppExpense(id: UUID(), title: "景点门票", amount: 360, payer: "王芳", date: makeDate(daysAgo: 6, hour: 10, minute: 10), participantCount: 4, participants: ["王芳", "张伟", "李娜", "赵磊"], note: "团体票", category: "娱乐"),
            AppExpense(id: UUID(), title: "夜宵烧烤", amount: 275, payer: "赵磊", date: makeDate(daysAgo: 7, hour: 23, minute: 15), participantCount: 4, participants: ["赵磊", "张伟", "李娜", "王芳"], note: "啤酒另点", category: "餐饮"),
            AppExpense(id: UUID(), title: "停车费", amount: 42, payer: "张伟", date: makeDate(daysAgo: 8, hour: 12, minute: 30), participantCount: 3, participants: ["张伟", "李娜", "王芳"], note: "商场地下车库", category: "交通"),
            AppExpense(id: UUID(), title: "纪念品", amount: 158, payer: "李娜", date: makeDate(daysAgo: 9, hour: 16, minute: 5), participantCount: 3, participants: ["李娜", "张伟", "王芳"], note: "冰箱贴和明信片", category: "购物")
        ]

        store.expenses = demoExpenses
        store.defaultParticipantCount = 4
        store.save()
    }
}