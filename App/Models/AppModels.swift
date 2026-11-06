import Foundation
import SwiftUI
import Combine

struct AppMedicineItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var category: String
    var storageLocation: String
    var quantity: Int
    var unit: String
    var expiryDate: Date
    var purchaseDate: Date
    var note: String
    var reminderEnabled: Bool
    var createdAt: Date

    init(name: String, category: String, storageLocation: String, quantity: Int, unit: String, expiryDate: Date, purchaseDate: Date, note: String, reminderEnabled: Bool, createdAt: Date = Date()) {
        self.name = name
        self.category = category
        self.storageLocation = storageLocation
        self.quantity = quantity
        self.unit = unit
        self.expiryDate = expiryDate
        self.purchaseDate = purchaseDate
        self.note = note
        self.reminderEnabled = reminderEnabled
        self.createdAt = createdAt
    }

    var daysUntilExpiry: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: expiryDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    var isExpired: Bool {
        daysUntilExpiry < 0
    }

    var isExpiringSoon: Bool {
        daysUntilExpiry >= 0 && daysUntilExpiry <= 30
    }
}

final class AppMedicineStore: ObservableObject {
    @Published var items: [AppMedicineItem] = []

    private var saveURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("home_med_cabinet.json")
    }

    init() {
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }

    private func load() {
        guard let url = saveURL,
              FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            items = try decoder.decode([AppMedicineItem].self, from: data)
        } catch {
            items = []
        }
    }

    func save() {
        guard let url = saveURL else { return }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(items)
            try data.write(to: url)
        } catch {
            print(error.localizedDescription)
        }
    }

    func add(_ item: AppMedicineItem) {
        items.append(item)
        save()
    }

    func update(_ item: AppMedicineItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            save()
        }
    }

    func delete(_ item: AppMedicineItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func toggleReminder(for item: AppMedicineItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].reminderEnabled.toggle()
            save()
        }
    }

    func itemsExpiringSoon() -> [AppMedicineItem] {
        items.filter { $0.isExpiringSoon }
    }

    func sortedByExpiry() -> [AppMedicineItem] {
        items.sorted { $0.expiryDate < $1.expiryDate }
    }
}

enum DemoSeed {
    static func apply(into store: AppMedicineStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }

        let now = Date()
        let calendar = Calendar.current

        func date(days: Int, hour: Int = 10, minute: Int = 0) -> Date {
            let base = calendar.date(byAdding: .day, value: days, to: now) ?? now
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        func pastDate(days: Int) -> Date {
            calendar.date(byAdding: .day, value: -days, to: now) ?? now
        }

        let demoItems: [AppMedicineItem] = [
            AppMedicineItem(name: "阿莫西林胶囊", category: "抗生素", storageLocation: "客厅药箱第一层", quantity: 2, unit: "盒", expiryDate: date(days: 18), purchaseDate: pastDate(days: 220), note: "饭后服用", reminderEnabled: true),
            AppMedicineItem(name: "布洛芬缓释胶囊", category: "解热镇痛", storageLocation: "卧室床头柜", quantity: 1, unit: "盒", expiryDate: date(days: 70), purchaseDate: pastDate(days: 300), note: "发烧超过38.5度服用", reminderEnabled: false),
            AppMedicineItem(name: "感冒灵颗粒", category: "感冒用药", storageLocation: "客厅药箱第二层", quantity: 3, unit: "盒", expiryDate: date(days: 45), purchaseDate: pastDate(days: 180), note: "一天三次", reminderEnabled: true),
            AppMedicineItem(name: "维生素D滴剂", category: "营养补充", storageLocation: "厨房冰箱门", quantity: 1, unit: "瓶", expiryDate: date(days: 240), purchaseDate: pastDate(days: 60), note: "每日两滴", reminderEnabled: false),
            AppMedicineItem(name: "氯雷他定片", category: "抗过敏", storageLocation: "书房抽屉", quantity: 2, unit: "盒", expiryDate: date(days: 12), purchaseDate: pastDate(days: 365), note: "睡前一片", reminderEnabled: true),
            AppMedicineItem(name: "蒙脱石散", category: "止泻药", storageLocation: "客厅药箱第三层", quantity: 4, unit: "包", expiryDate: date(days: 500), purchaseDate: pastDate(days: 90), note: "腹泻时服用", reminderEnabled: false),
            AppMedicineItem(name: "碘伏消毒液", category: "外用消毒", storageLocation: "浴室镜柜", quantity: 1, unit: "瓶", expiryDate: date(days: 365), purchaseDate: pastDate(days: 120), note: "开封后三个月内用完", reminderEnabled: false),
            AppMedicineItem(name: "创可贴", category: "外用护理", storageLocation: "玄关抽屉", quantity: 20, unit: "片", expiryDate: date(days: 600), purchaseDate: pastDate(days: 30), note: "防水型", reminderEnabled: false),
            AppMedicineItem(name: "连花清瘟胶囊", category: "感冒用药", storageLocation: "客厅药箱第一层", quantity: 1, unit: "盒", expiryDate: date(days: 6), purchaseDate: pastDate(days: 720), note: "遵医嘱", reminderEnabled: true),
            AppMedicineItem(name: "西瓜霜润喉片", category: "咽喉用药", storageLocation: "卧室梳妆台", quantity: 2, unit: "盒", expiryDate: date(days: 28), purchaseDate: pastDate(days: 150), note: "含服", reminderEnabled: true),
            AppMedicineItem(name: "开瑞坦", category: "抗过敏", storageLocation: "书房抽屉", quantity: 1, unit: "盒", expiryDate: date(days: 90), purchaseDate: pastDate(days: 110), note: "儿童减半", reminderEnabled: false),
            AppMedicineItem(name: "过期维生素C片", category: "营养补充", storageLocation: "储物间", quantity: 1, unit: "瓶", expiryDate: date(days: -10), purchaseDate: pastDate(days: 800), note: "已过期，待处理", reminderEnabled: false)
        ]

        store.items = demoItems
        store.save()
    }
}
