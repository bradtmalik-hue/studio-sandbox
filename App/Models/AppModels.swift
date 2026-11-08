import Foundation
import Combine

struct AppPetSupplyItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var expirationDate: Date
    var category: String
    var notes: String

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double,
        unit: String,
        expirationDate: Date,
        category: String,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.expirationDate = expirationDate
        self.category = category
        self.notes = notes
    }

    static let categories: [String] = [
        "狗粮",
        "猫粮",
        "零食",
        "玩具",
        "清洁",
        "药品"
    ]
}

final class AppInventoryStore: ObservableObject {
    @Published var items: [AppPetSupplyItem] = []

    private static let fileName = "AppPetSupplyItems.json"

    private static let fileURL: URL = {
        let directory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        return directory.appendingPathComponent(fileName)
    }()

    var totalItemCount: Int {
        items.count
    }

    var totalQuantity: Double {
        items.reduce(0) { $0 + $1.quantity }
    }

    var expiringSoonCount: Int {
        let threshold = Calendar.current.date(
            byAdding: .day,
            value: 30,
            to: Date()
        ) ?? Date()

        return items.filter { $0.expirationDate <= threshold }.count
    }

    var categoryBreakdown: [(String, Double)] {
        let grouped = Dictionary(grouping: items, by: \.category)

        return AppPetSupplyItem.categories.compactMap { category in
            let sum = grouped[category]?.reduce(0) { $0 + $1.quantity } ?? 0
            return (category, sum)
        }
    }

    var expiringSoonItems: [AppPetSupplyItem] {
        let threshold = Calendar.current.date(
            byAdding: .day,
            value: 30,
            to: Date()
        ) ?? Date()

        return items
            .filter { $0.expirationDate <= threshold }
            .sorted { $0.expirationDate < $1.expirationDate }
    }

    init() {
        load()

        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply()
        }
    }

    func add(_ item: AppPetSupplyItem) {
        items.append(item)
        save()
    }

    func update(_ item: AppPetSupplyItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        items[index] = item
        save()
    }

    func delete(_ item: AppPetSupplyItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func item(withID id: UUID) -> AppPetSupplyItem? {
        items.first { $0.id == id }
    }

    func load() {
        let url = Self.fileURL

        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            items = try decoder.decode([AppPetSupplyItem].self, from: data)
        } catch {
            items = []
        }
    }

    func save() {
        let url = Self.fileURL

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(items)
            try data.write(to: url)
        } catch {
            print("保存数据失败: \(error)")
        }
    }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else {
            return
        }

        let store = AppInventoryStore()
        apply(into: store)
    }

    static func apply(into store: AppInventoryStore) {
        guard CommandLine.arguments.contains("-demoData") else {
            return
        }

        let now = Date()
        let day: TimeInterval = 86_400

        let demoItems: [AppPetSupplyItem] = [
            AppPetSupplyItem(id: UUID(), name: "皇家幼猫粮", quantity: 2.5, unit: "千克", expirationDate: now.addingTimeInterval(45 * day), category: "猫粮", notes: "小颗粒，适合幼猫"),
            AppPetSupplyItem(id: UUID(), name: "渴望六种鱼全犬粮", quantity: 5.4, unit: "千克", expirationDate: now.addingTimeInterval(180 * day), category: "狗粮", notes: "大袋装，密封保存"),
            AppPetSupplyItem(id: UUID(), name: "路斯鸡肉条", quantity: 12, unit: "包", expirationDate: now.addingTimeInterval(30 * day), category: "零食", notes: "训练奖励用"),
            AppPetSupplyItem(id: UUID(), name: "耐咬磨牙棒", quantity: 8, unit: "根", expirationDate: now.addingTimeInterval(90 * day), category: "玩具", notes: "中大型犬适用"),
            AppPetSupplyItem(id: UUID(), name: "豆腐猫砂", quantity: 20, unit: "升", expirationDate: now.addingTimeInterval(300 * day), category: "清洁", notes: "原味，结团快"),
            AppPetSupplyItem(id: UUID(), name: "体外驱虫滴剂", quantity: 3, unit: "盒", expirationDate: now.addingTimeInterval(60 * day), category: "药品", notes: "每月一支"),
            AppPetSupplyItem(id: UUID(), name: "冻干鸡肉粒", quantity: 15, unit: "包", expirationDate: now.addingTimeInterval(25 * day), category: "零食", notes: "保质期较短，优先使用"),
            AppPetSupplyItem(id: UUID(), name: "宠物专用湿巾", quantity: 6, unit: "包", expirationDate: now.addingTimeInterval(365 * day), category: "清洁", notes: "擦脚擦毛用"),
            AppPetSupplyItem(id: UUID(), name: "瓦楞纸猫抓板", quantity: 3, unit: "块", expirationDate: now.addingTimeInterval(180 * day), category: "玩具", notes: "可替换装"),
            AppPetSupplyItem(id: UUID(), name: "宠物羊奶粉", quantity: 1.2, unit: "千克", expirationDate: now.addingTimeInterval(75 * day), category: "药品", notes: "幼宠补充营养")
        ]

        store.items = demoItems
        store.save()
    }
}