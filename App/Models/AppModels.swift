import Foundation
import Combine

struct AppMedicine: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var specification: String
    var manufacturer: String
    var category: String
    var location: String
    var quantity: Int
    var unit: String
    var expiryDate: Date
    var isOpened: Bool
    var notes: String
    var createdAt: Date

    init(id: UUID = UUID(),
         name: String = "",
         specification: String = "",
         manufacturer: String = "",
         category: String = "未分类",
         location: String = "未指定",
         quantity: Int = 1,
         unit: String = "盒",
         expiryDate: Date = Date(),
         isOpened: Bool = false,
         notes: String = "",
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.specification = specification
        self.manufacturer = manufacturer
        self.category = category
        self.location = location
        self.quantity = quantity
        self.unit = unit
        self.expiryDate = expiryDate
        self.isOpened = isOpened
        self.notes = notes
        self.createdAt = createdAt
    }
}

final class AppMedicineStore: ObservableObject {
    @Published var medicines: [AppMedicine] = []
    @Published var categories: [String] = ["感冒用药", "儿童用药", "外用药品", "消化用药", "其他"]

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("AppMedicines.json")
    }

    init() {
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply()
        }
    }

    func add(_ medicine: AppMedicine) {
        medicines.append(medicine)
        save()
    }

    func update(_ medicine: AppMedicine) {
        if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
            medicines[index] = medicine
            save()
        }
    }

    func delete(at offsets: IndexSet) {
        medicines.remove(atOffsets: offsets)
        save()
    }

    func delete(_ medicine: AppMedicine) {
        medicines.removeAll { $0.id == medicine.id }
        save()
    }

    func addCategory(_ name: String) {
        guard !name.isEmpty else { return }
        if !categories.contains(name) {
            categories.append(name)
        }
    }

    var totalQuantity: Int {
        medicines.reduce(0) { $0 + $1.quantity }
    }

    var nearestExpiryDate: Date? {
        medicines.min(by: { $0.expiryDate < $1.expiryDate })?.expiryDate
    }

    var expiringSoonCount: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let thirtyDaysLater = calendar.date(byAdding: .day, value: 30, to: now) else { return 0 }
        return medicines.filter { $0.expiryDate >= now && $0.expiryDate <= thirtyDaysLater }.count
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(medicines)
            try data.write(to: fileURL)
        } catch {
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            medicines = try decoder.decode([AppMedicine].self, from: data)
        } catch {
            medicines = []
        }
    }
}

enum DemoSeed {
    static func apply() {
        let store = AppMedicineStore()
        apply(into: store)
    }

    static func apply(into store: AppMedicineStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }
        let calendar = Calendar.current
        let now = Date()
        func days(_ dayOffset: Int) -> Date {
            calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
        }

        let samples: [AppMedicine] = [
            AppMedicine(name: "布洛芬缓释胶囊", specification: "0.3g*20粒", manufacturer: "中美天津史克", category: "感冒用药", location: "客厅药箱上层", quantity: 2, unit: "盒", expiryDate: days(10), isOpened: true, notes: "开封后注意防潮"),
            AppMedicine(name: "对乙酰氨基酚片", specification: "0.5g*12片", manufacturer: "上海强生", category: "感冒用药", location: "卧室床头柜", quantity: 1, unit: "盒", expiryDate: days(25), isOpened: false, notes: "退烧时服用"),
            AppMedicine(name: "小儿氨酚黄那敏颗粒", specification: "2g*10袋", manufacturer: "三九感冒灵", category: "儿童用药", location: "儿童房抽屉", quantity: 3, unit: "盒", expiryDate: days(380), isOpened: true, notes: "儿童专用"),
            AppMedicine(name: "蒙脱石散", specification: "3g*10袋", manufacturer: "博福-益普生", category: "消化用药", location: "厨房药箱", quantity: 2, unit: "盒", expiryDate: days(45), isOpened: false, notes: ""),
            AppMedicine(name: "碘伏消毒液", specification: "100ml", manufacturer: "山东利尔康", category: "外用药品", location: "卫生间镜柜", quantity: 2, unit: "瓶", expiryDate: days(200), isOpened: true, notes: ""),
            AppMedicine(name: "创可贴", specification: "20片装", manufacturer: "云南白药", category: "外用药品", location: "客厅药箱下层", quantity: 5, unit: "盒", expiryDate: days(500), isOpened: false, notes: ""),
            AppMedicine(name: "藿香正气水", specification: "10ml*10支", manufacturer: "北京同仁堂", category: "其他", location: "玄关柜", quantity: 1, unit: "盒", expiryDate: days(15), isOpened: false, notes: "夏季备用"),
            AppMedicine(name: "阿莫西林胶囊", specification: "0.25g*24粒", manufacturer: "华北制药", category: "感冒用药", location: "客厅药箱上层", quantity: 1, unit: "盒", expiryDate: days(8), isOpened: false, notes: "处方药"),
            AppMedicine(name: "维生素C片", specification: "100片", manufacturer: "汤臣倍健", category: "其他", location: "卧室书架", quantity: 1, unit: "瓶", expiryDate: days(300), isOpened: true, notes: "每天一片"),
            AppMedicine(name: "氯雷他定片", specification: "10mg*6片", manufacturer: "拜耳", category: "感冒用药", location: "客厅药箱下层", quantity: 2, unit: "盒", expiryDate: days(60), isOpened: false, notes: "过敏时服用"),
            AppMedicine(name: "儿童退热贴", specification: "4贴", manufacturer: "小葵花", category: "儿童用药", location: "儿童房抽屉", quantity: 3, unit: "盒", expiryDate: days(700), isOpened: false, notes: ""),
            AppMedicine(name: "开塞露", specification: "20ml*2支", manufacturer: "北京曙光", category: "消化用药", location: "卫生间储物柜", quantity: 2, unit: "盒", expiryDate: days(120), isOpened: false, notes: "")
        ]
        store.medicines = samples
        store.save()
    }
}