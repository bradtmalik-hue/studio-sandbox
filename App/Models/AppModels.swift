import Foundation
import Combine

struct AppMedicine: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var category: String
    var expiryDate: Date
    var location: String
    var quantity: Int
    var notes: String = ""

    var isExpired: Bool {
        expiryDate < Date()
    }

    var daysUntilExpiry: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfExpiry = calendar.startOfDay(for: expiryDate)
        return calendar.dateComponents([.day], from: startOfToday, to: startOfExpiry).day ?? 0
    }
}

enum AppMedicineCategory: String, Codable, CaseIterable {
    case cold = "感冒用药"
    case pain = "止痛退烧"
    case digestion = "肠胃用药"
    case allergy = "过敏用药"
    case firstAid = "急救护理"
    case chronic = "慢性病用药"
    case vitamins = "维生素/保健品"
    case other = "其他"
}

final class AppStore: ObservableObject {
    static let shared = AppStore()

    @Published var medicines: [AppMedicine] = []
    @Published var searchText: String = ""

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documents.appendingPathComponent("family_medicine_cabinet.json")
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply()
        }
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            medicines = try decoder.decode([AppMedicine].self, from: data)
                .sorted { $0.expiryDate < $1.expiryDate }
        } catch {
            medicines = []
        }
    }

    func save() {
        do {
            let data = try encoder.encode(medicines)
            try data.write(to: fileURL)
        } catch {
            print("保存失败: \(error.localizedDescription)")
        }
    }

    func add(_ medicine: AppMedicine) {
        medicines.append(medicine)
        sortByExpiry()
        save()
    }

    func update(_ medicine: AppMedicine) {
        if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
            medicines[index] = medicine
            sortByExpiry()
            save()
        }
    }

    func delete(_ medicine: AppMedicine) {
        medicines.removeAll { $0.id == medicine.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        medicines.remove(atOffsets: offsets)
        save()
    }

    func sortByExpiry() {
        medicines.sort { $0.expiryDate < $1.expiryDate }
    }

    var expiredMedicines: [AppMedicine] {
        medicines.filter { $0.isExpired }
    }

    var expiringSoonMedicines: [AppMedicine] {
        let soon = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        return medicines.filter { $0.expiryDate >= Date() && $0.expiryDate < soon }
    }

    var allLocations: [String] {
        Array(Set(medicines.map(\.location))).sorted()
    }
}

enum DemoSeed {
    private static var seeded = false

    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
        apply(into: AppStore.shared)
    }

    static func apply(into store: AppStore) {
        seeded = true
        let calendar = Calendar.current
        let now = Date()

        func date(daysFromNow: Int, hour: Int = 9) -> Date {
            let day = calendar.date(byAdding: .day, value: daysFromNow, to: now) ?? now
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
        }

        let demoMedicines = [
            AppMedicine(id: UUID(), name: "感冒灵颗粒", category: AppMedicineCategory.cold.rawValue, expiryDate: date(daysFromNow: -20, hour: 8), location: "客厅电视柜右侧抽屉", quantity: 1, notes: "早晚各一包，已过期请勿服用", isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "对乙酰氨基酚片", category: AppMedicineCategory.pain.rawValue, expiryDate: date(daysFromNow: 25, hour: 9), location: "客厅电视柜右侧抽屉", quantity: 1, notes: "发烧超过38.5℃再服用", isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "布洛芬缓释胶囊", category: AppMedicineCategory.pain.rawValue, expiryDate: date(daysFromNow: 120, hour: 10), location: "卧室床头柜第一层", quantity: 2, notes: "头痛、牙痛备用", isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "蒙脱石散", category: AppMedicineCategory.digestion.rawValue, expiryDate: date(daysFromNow: 60, hour: 9), location: "厨房吊柜上层", quantity: 3, notes: "腹泻时饭前服用", isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "氯雷他定片", category: AppMedicineCategory.allergy.rawValue, expiryDate: date(daysFromNow: 300, hour: 9), location: "卧室衣柜顶收纳盒", quantity: 1, notes: "过敏性鼻炎备用", isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "阿莫西林胶囊", category: AppMedicineCategory.cold.rawValue, expiryDate: date(daysFromNow: 45, hour: 9), location: "书房书架第二层", quantity: 2, notes: "遵医嘱使用", isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "创可贴", category: AppMedicineCategory.firstAid.rawValue, expiryDate: date(daysFromNow: 730, hour: 8), location: "玄关鞋柜小药盒", quantity: 20, notes: "小伤口应急", isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "维生素C片", category: AppMedicineCategory.vitamins.rawValue, expiryDate: date(daysFromNow: 200, hour: 8), location: "餐厅餐边柜抽屉", quantity: 1, notes: "每日一片", isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "胰岛素注射液", category: AppMedicineCategory.chronic.rawValue, expiryDate: date(daysFromNow: 90, hour: 8), location: "冰箱冷藏室门架", quantity: 2, notes: "未开封冷藏保存", isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "云南白药气雾剂", category: AppMedicineCategory.firstAid.rawValue, expiryDate: date(daysFromNow: 150, hour: 10), location: "卫生间镜柜下层", quantity: 1, notes: "跌打损伤", isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "奥美拉唑肠溶胶囊", category: AppMedicineCategory.digestion.rawValue, expiryDate: date(daysFromNow: 75, hour: 9), location: "卧室床头柜第二层", quantity: 3, notes: "饭前服用", isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "碘伏棉签", category: AppMedicineCategory.firstAid.rawValue, expiryDate: date(daysFromNow: 540, hour: 8), location: "玄关鞋柜小药盒", quantity: 2, notes: "消毒用", isExpired: false, daysUntilExpiry: 0)
        ]

        store.medicines = demoMedicines.sorted { $0.expiryDate < $1.expiryDate }
        store.save()
    }
}