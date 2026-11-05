import Foundation
import Combine
import SwiftUI

enum AppMedicineCategory: String, Codable, CaseIterable, Identifiable {
    case prescription = "处方药"
    case otc = "非处方药"
    case supplement = "保健品"
    case topical = "外用药"
    case other = "其他"
    var id: String { rawValue }
}

enum AppStorageLocation: String, Codable, CaseIterable, Identifiable {
    case medicineCabinet = "药柜"
    case fridge = "冰箱"
    case drawer = "抽屉"
    case storageBox = "收纳盒"
    case bedsideTable = "床头柜"
    case other = "其他"
    var id: String { rawValue }
}

struct AppMedicineItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var category: AppMedicineCategory
    var expiryDate: Date
    var storageSpot: AppStorageLocation
    var quantity: Int
    var notes: String
    var createdAt: Date = Date()
}

class AppMedicineStore: ObservableObject {
    @Published var medicines: [AppMedicineItem] {
        didSet { save() }
    }

    static let storageLocations = AppStorageLocation.allCases
    static let categories = AppMedicineCategory.allCases

    private let fileName = "medicines.json"
    private var dataFileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }

    init() {
        self.medicines = []
        load()
    }

    func load() {
        let url = dataFileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            medicines = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            medicines = try decoder.decode([AppMedicineItem].self, from: data)
        } catch {
            medicines = []
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(medicines)
            try data.write(to: dataFileURL)
        } catch {
            // ignore write errors for now
        }
    }

    func add(_ item: AppMedicineItem) {
        medicines.append(item)
    }

    func update(_ item: AppMedicineItem) {
        guard let index = medicines.firstIndex(where: { $0.id == item.id }) else { return }
        medicines[index] = item
    }

    func delete(at offsets: IndexSet) {
        medicines.remove(atOffsets: offsets)
    }

    func delete(_ item: AppMedicineItem) {
        medicines.removeAll { $0.id == item.id }
    }

    func sortedByExpiry() -> [AppMedicineItem] {
        medicines.sorted { $0.expiryDate < $1.expiryDate }
    }

    func expiredCount() -> Int {
        medicines.filter { $0.expiryDate < Date() }.count
    }

    func expiringSoonCount(within days: Int = 30) -> Int {
        let future = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return medicines.filter { $0.expiryDate >= Date() && $0.expiryDate <= future }.count
    }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
        let store = AppMedicineStore()
        guard store.medicines.isEmpty else { return }

        let calendar = Calendar.current
        let now = Date()

        func date(days: Int) -> Date {
            calendar.date(byAdding: .day, value: days, to: now) ?? now
        }

        let samples: [AppMedicineItem] = [
            AppMedicineItem(name: "阿莫西林胶囊", category: .prescription, expiryDate: date(days: 120), storageSpot: .medicineCabinet, quantity: 2, notes: "每日三次，每次一粒"),
            AppMedicineItem(name: "布洛芬缓释胶囊", category: .otc, expiryDate: date(days: 300), storageSpot: .drawer, quantity: 1, notes: "头痛时服用"),
            AppMedicineItem(name: "维生素C片", category: .supplement, expiryDate: date(days: 200), storageSpot: .storageBox, quantity: 3, notes: "每日一片"),
            AppMedicineItem(name: "红霉素软膏", category: .topical, expiryDate: date(days: 45), storageSpot: .bedsideTable, quantity: 1, notes: "外用，涂抹患处"),
            AppMedicineItem(name: "感冒灵颗粒", category: .otc, expiryDate: date(days: 360), storageSpot: .medicineCabinet, quantity: 5, notes: "一次一袋，一日三次"),
            AppMedicineItem(name: "蒙脱石散", category: .otc, expiryDate: date(days: 90), storageSpot: .drawer, quantity: 2, notes: "腹泻时服用"),
            AppMedicineItem(name: "创可贴", category: .other, expiryDate: date(days: 730), storageSpot: .drawer, quantity: 20, notes: "小伤口使用"),
            AppMedicineItem(name: "氯雷他定片", category: .otc, expiryDate: date(days: 180), storageSpot: .fridge, quantity: 1, notes: "过敏时服用，一天一片"),
            AppMedicineItem(name: "眼药水", category: .other, expiryDate: date(days: 60), storageSpot: .fridge, quantity: 1, notes: "开封后一个月内用完"),
            AppMedicineItem(name: "藿香正气水", category: .otc, expiryDate: date(days: 400), storageSpot: .medicineCabinet, quantity: 6, notes: "中暑时服用"),
            AppMedicineItem(name: "云南白药气雾剂", category: .topical, expiryDate: date(days: 150), storageSpot: .storageBox, quantity: 2, notes: "跌打损伤"),
            AppMedicineItem(name: "阿司匹林肠溶片", category: .prescription, expiryDate: date(days: 500), storageSpot: .medicineCabinet, quantity: 1, notes: "遵医嘱服用")
        ]

        store.medicines = samples
        store.save()
    }
}