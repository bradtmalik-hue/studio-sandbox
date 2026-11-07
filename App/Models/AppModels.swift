import Foundation
import Combine

struct AppMedicineBox: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var category: String
    var expiryDate: Date
    var storageLocation: String
    var quantity: Int
    var unit: String
    var reminderEnabled: Bool
    var notes: String
    var createdAt: Date
}

final class AppStore: ObservableObject {
    @Published var medicines: [AppMedicineBox] = []

    private let fileName = "AppMedicineBoxes.json"
    private let fileManager = FileManager.default

    var fileURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    init() {
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }

    func load() {
        let url = fileURL
        guard fileManager.fileExists(atPath: url.path) else {
            medicines = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([AppMedicineBox].self, from: data)
            medicines = decoded
        } catch {
            medicines = []
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(medicines)
            try data.write(to: fileURL)
        } catch {
            print("Save failed: \(error.localizedDescription)")
        }
    }

    func add(_ medicine: AppMedicineBox) {
        medicines.append(medicine)
        save()
    }

    func update(_ medicine: AppMedicineBox) {
        guard let index = medicines.firstIndex(where: { $0.id == medicine.id }) else { return }
        medicines[index] = medicine
        save()
    }

    func delete(_ medicine: AppMedicineBox) {
        medicines.removeAll { $0.id == medicine.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        medicines.remove(atOffsets: offsets)
        save()
    }
}

enum DemoSeed {
    static func apply(into store: AppStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }

        let now = Date()
        let calendar = Calendar.current

        func days(_ value: Int) -> Date {
            calendar.date(byAdding: .day, value: value, to: now) ?? now
        }

        let samples: [AppMedicineBox] = [
            AppMedicineBox(
                id: UUID(),
                name: "布洛芬缓释胶囊",
                category: "解热镇痛",
                expiryDate: days(18),
                storageLocation: "客厅药箱上层",
                quantity: 2,
                unit: "盒",
                reminderEnabled: true,
                notes: "牙痛或发热时用，饭后服用",
                createdAt: days(-120)
            ),
            AppMedicineBox(
                id: UUID(),
                name: "阿莫西林胶囊",
                category: "抗生素",
                expiryDate: days(9),
                storageLocation: "卧室床头柜",
                quantity: 1,
                unit: "盒",
                reminderEnabled: true,
                notes: "对青霉素过敏者禁用",
                createdAt: days(-80)
            ),
            AppMedicineBox(
                id: UUID(),
                name: "氯雷他定片",
                category: "抗过敏",
                expiryDate: days(37),
                storageLocation: "药箱第二层",
                quantity: 1,
                unit: "盒",
                reminderEnabled: false,
                notes: "季节性鼻炎备用",
                createdAt: days(-60)
            ),
            AppMedicineBox(
                id: UUID(),
                name: "蒙脱石散",
                category: "止泻",
                expiryDate: days(26),
                storageLocation: "厨房吊柜",
                quantity: 3,
                unit: "袋",
                reminderEnabled: true,
                notes: "腹泻时空腹服用",
                createdAt: days(-45)
            ),
            AppMedicineBox(
                id: UUID(),
                name: "维生素D滴剂",
                category: "营养补充",
                expiryDate: days(180),
                storageLocation: "冰箱冷藏格",
                quantity: 1,
                unit: "瓶",
                reminderEnabled: false,
                notes: "每日一次，每次两滴",
                createdAt: days(-30)
            ),
            AppMedicineBox(
                id: UUID(),
                name: "创可贴",
                category: "外用",
                expiryDate: days(365),
                storageLocation: "玄关抽屉",
                quantity: 20,
                unit: "片",
                reminderEnabled: false,
                notes: "小伤口备用",
                createdAt: days(-200)
            ),
            AppMedicineBox(
                id: UUID(),
                name: "云南白药气雾剂",
                category: "跌打损伤",
                expiryDate: days(45),
                storageLocation: "运动包侧袋",
                quantity: 1,
                unit: "瓶",
                reminderEnabled: true,
                notes: "扭伤后使用",
                createdAt: days(-15)
            ),
            AppMedicineBox(
                id: UUID(),
                name: "左氧氟沙星滴眼液",
                category: "眼科用药",
                expiryDate: days(12),
                storageLocation: "药箱第一层",
                quantity: 1,
                unit: "支",
                reminderEnabled: true,
                notes: "开封后一个月内用完",
                createdAt: days(-10)
            ),
            AppMedicineBox(
                id: UUID(),
                name: "感冒灵颗粒",
                category: "感冒",
                expiryDate: days(23),
                storageLocation: "客厅电视柜",
                quantity: 2,
                unit: "盒",
                reminderEnabled: false,
                notes: "早晚各一袋",
                createdAt: days(-50)
            ),
            AppMedicineBox(
                id: UUID(),
                name: "开塞露",
                category: "通便",
                expiryDate: days(150),
                storageLocation: "卫生间镜柜",
                quantity: 5,
                unit: "支",
                reminderEnabled: false,
                notes: "便秘备用",
                createdAt: days(-90)
            ),
            AppMedicineBox(
                id: UUID(),
                name: "碘伏棉签",
                category: "外用消毒",
                expiryDate: days(30),
                storageLocation: "药箱第三层",
                quantity: 1,
                unit: "盒",
                reminderEnabled: true,
                notes: "伤口消毒用",
                createdAt: days(-5)
            ),
            AppMedicineBox(
                id: UUID(),
                name: "电子体温计",
                category: "器械",
                expiryDate: days(720),
                storageLocation: "床头柜第二层",
                quantity: 1,
                unit: "支",
                reminderEnabled: false,
                notes: "定期更换电池",
                createdAt: days(-300)
            )
        ]

        store.medicines = samples
        store.save()
    }
}