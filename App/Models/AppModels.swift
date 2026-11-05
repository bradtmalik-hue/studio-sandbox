import Foundation
import Combine

struct AppMedicineItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var category: String
    var storageLocation: String
    var expiryDate: Date
    var quantity: Int = 1
    var note: String = ""
    var createdAt: Date = Date()
}

final class AppMedicineStore: ObservableObject {
    @Published private(set) var items: [AppMedicineItem] = []

    private static let documentsDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private static let defaultFileURL: URL = documentsDirectory.appendingPathComponent("home_medbox_items.json")

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL = AppMedicineStore.defaultFileURL) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        load()
    }

    var sortedByExpiry: [AppMedicineItem] {
        items.sorted { $0.expiryDate < $1.expiryDate }
    }

    var expiredItems: [AppMedicineItem] {
        sortedByExpiry.filter { $0.expiryDate < Date() }
    }

    var expiringSoonItems: [AppMedicineItem] {
        let now = Date()
        let upcoming = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now
        return sortedByExpiry.filter { $0.expiryDate >= now && $0.expiryDate < upcoming }
    }

    var activeItems: [AppMedicineItem] {
        sortedByExpiry.filter { $0.expiryDate >= Date() }
    }

    func item(with id: UUID) -> AppMedicineItem? {
        items.first { $0.id == id }
    }

    func add(_ item: AppMedicineItem) {
        items.append(item)
        save()
    }

    func update(_ item: AppMedicineItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        save()
    }

    func delete(_ item: AppMedicineItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func filteredItems(searchText: String) -> [AppMedicineItem] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return sortedByExpiry }
        return sortedByExpiry.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed) ||
            $0.category.localizedCaseInsensitiveContains(trimmed) ||
            $0.storageLocation.localizedCaseInsensitiveContains(trimmed) ||
            $0.note.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? decoder.decode([AppMedicineItem].self, from: data) {
            items = decoded
        }
    }

    private func save() {
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: fileURL)
    }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
        let store = AppMedicineStore()
        guard store.items.isEmpty else { return }

        func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
            Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
        }

        let samples: [AppMedicineItem] = [
            AppMedicineItem(
                name: "布洛芬缓释胶囊",
                category: "解热镇痛",
                storageLocation: "客厅电视柜左侧药箱",
                expiryDate: makeDate(2025, 8, 15),
                quantity: 2,
                note: "饭后服用"
            ),
            AppMedicineItem(
                name: "阿莫西林胶囊",
                category: "抗生素",
                storageLocation: "主卧床头柜第二层",
                expiryDate: makeDate(2025, 6, 30),
                quantity: 1,
                note: "注意过敏"
            ),
            AppMedicineItem(
                name: "氯雷他定片",
                category: "抗过敏",
                storageLocation: "厨房冰箱门上药盒",
                expiryDate: makeDate(2025, 11, 1),
                quantity: 1,
                note: "每日一次"
            ),
            AppMedicineItem(
                name: "维生素D滴剂",
                category: "维生素",
                storageLocation: "儿童房抽屉药盒",
                expiryDate: makeDate(2026, 1, 10),
                quantity: 1,
                note: "睡前滴"
            ),
            AppMedicineItem(
                name: "云南白药气雾剂",
                category: "外用药",
                storageLocation: "卫生间镜柜上格",
                expiryDate: makeDate(2025, 9, 12),
                quantity: 1,
                note: "跌打损伤"
            ),
            AppMedicineItem(
                name: "碘伏消毒液",
                category: "外用药",
                storageLocation: "卫生间镜柜下格",
                expiryDate: makeDate(2025, 10, 30),
                quantity: 1,
                note: "开封后密封保存"
            ),
            AppMedicineItem(
                name: "感冒灵颗粒",
                category: "感冒用药",
                storageLocation: "客厅电视柜右侧抽屉",
                expiryDate: makeDate(2025, 7, 20),
                quantity: 3,
                note: "每次一袋"
            ),
            AppMedicineItem(
                name: "蒙脱石散",
                category: "止泻药",
                storageLocation: "厨房吊柜左侧",
                expiryDate: makeDate(2025, 9, 25),
                quantity: 2,
                note: "空腹服用"
            ),
            AppMedicineItem(
                name: "硝酸甘油片",
                category: "急救用药",
                storageLocation: "妈妈随身包夹层",
                expiryDate: makeDate(2026, 3, 5),
                quantity: 1,
                note: "避光保存"
            ),
            AppMedicineItem(
                name: "对乙酰氨基酚片",
                category: "解热镇痛",
                storageLocation: "书房书桌左下抽屉",
                expiryDate: makeDate(2025, 12, 15),
                quantity: 1,
                note: "体温38.5℃以上使用"
            )
        ]

        samples.forEach { store.add($0) }
    }
}