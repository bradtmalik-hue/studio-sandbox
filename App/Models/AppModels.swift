import Foundation
import Combine

struct AppMealRecord: Codable, Identifiable {
    let id: UUID
    var date: Date
    var amount: Double // 单位：克
    var note: String

    init(id: UUID = UUID(), date: Date = Date(), amount: Double = 0, note: String = "") {
        self.id = id
        self.date = date
        self.amount = amount
        self.note = note
    }
}

final class AppMealStore: ObservableObject {
    @Published var records: [AppMealRecord] = []

    private let fileName = "meal_records.json"

    private var fileURL: URL? {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents?.appendingPathComponent(fileName)
    }

    init() {
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }

    init(_ configure: (AppMealStore) -> Void) {
        load()
        configure(self)
    }

    func add(_ record: AppMealRecord) {
        records.append(record)
        save()
    }

    func update(_ record: AppMealRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
        save()
    }

    func delete(_ record: AppMealRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    func save() {
        guard let url = fileURL else { return }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(records)
            try data.write(to: url)
        } catch {
            print("保存失败: \(error)")
        }
    }

    func load() {
        guard let url = fileURL, FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            records = try decoder.decode([AppMealRecord].self, from: data)
        } catch {
            print("加载失败: \(error)")
        }
    }
}

enum DemoSeed {
    static let demoData: [(daysAgo: Int, hour: Int, minute: Int, amount: Double, note: String)] = [
        (0, 7, 40, 35, "干粮"),
        (0, 19, 15, 50, "湿粮"),
        (1, 8, 5, 38, "干粮"),
        (1, 20, 30, 45, "湿粮"),
        (2, 7, 55, 32, "干粮"),
        (2, 18, 45, 48, "湿粮"),
        (3, 8, 20, 40, "干粮"),
        (3, 21, 10, 55, "湿粮"),
        (4, 7, 50, 30, "干粮"),
        (4, 19, 40, 50, "湿粮"),
        (5, 8, 15, 42, "干粮"),
        (5, 20, 5, 46, "湿粮")
    ]

    static func apply(into store: AppMealStore? = nil) {
        // 只在启动参数包含 -demoData 时执行
        guard CommandLine.arguments.contains("-demoData") else { return }
        guard let store = store else { return }

        store.records = []

        let calendar = Calendar.current
        let today = Date()
        // 生成最近 7 天的喂食记录，尽量真实
        for item in demoData {
            let date = calendar.date(byAdding: .day, value: -item.daysAgo, to: today) ?? today
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            var finalComponents = DateComponents()
            finalComponents.year = components.year
            finalComponents.month = components.month
            finalComponents.day = components.day
            finalComponents.hour = item.hour
            finalComponents.minute = item.minute
            let finalDate = calendar.date(from: finalComponents) ?? date
            store.records.append(AppMealRecord(date: finalDate, amount: item.amount, note: item.note))
        }

        store.save()
    }
}