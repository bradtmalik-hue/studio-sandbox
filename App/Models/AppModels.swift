import Foundation
import SwiftUI
import Combine

struct AppMedicine: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var specification: String
    var quantity: Int
    var unit: String
    var expiryDate: Date
    var location: String
    var dateAdded: Date = Date()
    var notes: String = ""
    var isFavorite: Bool = false

    var isExpired: Bool {
        expiryDate < Date()
    }

    var daysUntilExpiry: Int {
        let start = Calendar.current.startOfDay(for: Date())
        let target = Calendar.current.startOfDay(for: expiryDate)
        return Calendar.current.dateComponents([.day], from: start, to: target).day ?? 0
    }
}

final class AppStore: ObservableObject {
    @Published var medicines: [AppMedicine] = []
    @Published var locations: [String] = ["客厅药箱", "卧室抽屉", "冰箱冷藏", "厨房柜子", "随身包"]

    private struct PersistedData: Codable {
        var medicines: [AppMedicine]
        var locations: [String]
    }

    private var persistenceURL: URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("familyMedicineCabinet.json")
    }

    init() {
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply()
        }
    }

    func load() {
        do {
            let data = try Data(contentsOf: persistenceURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let persisted = try decoder.decode(PersistedData.self, from: data)
            medicines = persisted.medicines
            locations = persisted.locations
        } catch {
            medicines = []
            locations = ["客厅药箱", "卧室抽屉", "冰箱冷藏", "厨房柜子", "随身包"]
        }
    }

    func save() {
        let persisted = PersistedData(medicines: medicines, locations: locations)
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(persisted)
            try data.write(to: persistenceURL)
        } catch {
            print("保存失败: \(error)")
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

    func delete(_ medicine: AppMedicine) {
        medicines.removeAll { $0.id == medicine.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        medicines.remove(atOffsets: offsets)
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        medicines.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func addLocation(_ location: String) {
        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !locations.contains(trimmed) else { return }
        locations.append(trimmed)
        save()
    }

    var allLocations: [String] {
        Array(Set(medicines.map(\.location) + locations)).sorted()
    }

    var expiringSoonMedicines: [AppMedicine] {
        medicines.filter { $0.daysUntilExpiry >= 0 && $0.daysUntilExpiry <= 90 }
    }

    var expiredMedicines: [AppMedicine] {
        medicines.filter { $0.isExpired }
    }

    var freshMedicines: [AppMedicine] {
        medicines.filter { $0.daysUntilExpiry > 90 }
    }

    func medicines(in location: String) -> [AppMedicine] {
        medicines.filter { $0.location == location }
    }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
        let store = AppStore()
        apply(into: store)
    }

    static func apply(into store: AppStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }
        let now = Date()
        let cal = Calendar.current
        func day(_ offset: Int) -> Date {
            cal.date(byAdding: .day, value: offset, to: now) ?? now
        }
        func month(_ offset: Int) -> Date {
            cal.date(byAdding: .month, value: offset, to: now) ?? now
        }

        let demoMedicines: [AppMedicine] = [
            AppMedicine(id: UUID(), name: "布洛芬缓释胶囊", specification: "0.3g*20粒", quantity: 2, unit: "盒", expiryDate: month(8), location: "客厅药箱", dateAdded: day(-10), notes: "头痛、牙痛备用", isFavorite: true, isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "阿莫西林胶囊", specification: "0.25g*24粒", quantity: 1, unit: "盒", expiryDate: month(3), location: "卧室抽屉", dateAdded: day(-5), notes: "细菌感染时遵医嘱", isFavorite: false, isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "感冒灵颗粒", specification: "10g*9袋", quantity: 3, unit: "盒", expiryDate: month(14), location: "客厅药箱", dateAdded: day(-30), notes: "风寒感冒", isFavorite: true, isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "维生素C片", specification: "100片/瓶", quantity: 1, unit: "瓶", expiryDate: month(20), location: "厨房柜子", dateAdded: day(-60), notes: "每日一片", isFavorite: false, isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "氯雷他定片", specification: "10mg*6片", quantity: 2, unit: "盒", expiryDate: month(6), location: "卧室抽屉", dateAdded: day(-15), notes: "过敏性鼻炎", isFavorite: true, isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "蒙脱石散", specification: "3g*10袋", quantity: 2, unit: "盒", expiryDate: month(11), location: "冰箱冷藏", dateAdded: day(-20), notes: "腹泻备用", isFavorite: false, isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "藿香正气水", specification: "10ml*10支", quantity: 1, unit: "盒", expiryDate: month(9), location: "客厅药箱", dateAdded: day(-40), notes: "暑湿感冒", isFavorite: false, isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "碘伏消毒液", specification: "100ml", quantity: 1, unit: "瓶", expiryDate: month(18), location: "厨房柜子", dateAdded: day(-80), notes: "外伤消毒", isFavorite: false, isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "创可贴", specification: "100片/盒", quantity: 1, unit: "盒", expiryDate: month(24), location: "随身包", dateAdded: day(-100), notes: "小伤口", isFavorite: true, isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "对乙酰氨基酚片", specification: "0.5g*20片", quantity: 1, unit: "盒", expiryDate: month(4), location: "卧室抽屉", dateAdded: day(-7), notes: "退烧止痛", isFavorite: false, isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "奥美拉唑肠溶胶囊", specification: "20mg*14粒", quantity: 1, unit: "盒", expiryDate: month(7), location: "冰箱冷藏", dateAdded: day(-12), notes: "胃酸过多", isFavorite: false, isExpired: false, daysUntilExpiry: 0),
            AppMedicine(id: UUID(), name: "健胃消食片", specification: "0.8g*32片", quantity: 2, unit: "盒", expiryDate: month(16), location: "客厅药箱", dateAdded: day(-25), notes: "消化不良", isFavorite: false, isExpired: false, daysUntilExpiry: 0)
        ]

        store.medicines = demoMedicines
        store.locations = ["客厅药箱", "卧室抽屉", "冰箱冷藏", "厨房柜子", "随身包"]
        store.save()
    }
}