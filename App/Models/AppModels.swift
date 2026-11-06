import Foundation
import Combine

struct AppMedicine: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var expiryDate: Date
    var location: String
    var quantity: Int

    init(
        id: UUID = UUID(),
        name: String,
        expiryDate: Date,
        location: String,
        quantity: Int = 1
    ) {
        self.id = id
        self.name = name
        self.expiryDate = expiryDate
        self.location = location
        self.quantity = quantity
    }
}

final class AppMedicineStore: ObservableObject {
    @Published var medicines: [AppMedicine] = []

    private let fileName = "medicines.json"

    init() {
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }

    var sortedByExpiry: [AppMedicine] {
        medicines.sorted { $0.expiryDate < $1.expiryDate }
    }

    var expiringSoon: [AppMedicine] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let threshold = calendar.date(byAdding: .day, value: 30, to: today) ?? today
        return medicines
            .filter { $0.expiryDate >= today && $0.expiryDate <= threshold }
            .sorted { $0.expiryDate < $1.expiryDate }
    }

    func add(_ medicine: AppMedicine) {
        medicines.append(medicine)
        save()
    }

    func update(_ medicine: AppMedicine) {
        guard let index = medicines.firstIndex(where: { $0.id == medicine.id }) else {
            return
        }
        medicines[index] = medicine
        save()
    }

    func delete(_ medicine: AppMedicine) {
        medicines.removeAll { $0.id == medicine.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        medicines.remove(atOffsets: offsets)
        save()
    }

    func save() {
        guard let url = fileURL else {
            return
        }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(medicines)
            try data.write(to: url)
        } catch {
            return
        }
    }

    private var fileURL: URL? {
        let fileManager = FileManager.default
        guard let directory = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }
        return directory.appendingPathComponent(fileName)
    }

    private func load() {
        guard let url = fileURL else {
            medicines = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            medicines = try decoder.decode([AppMedicine].self, from: data)
        } catch {
            medicines = []
        }
    }
}

enum DemoSeed {
    static func apply(into store: AppMedicineStore) {
        guard CommandLine.arguments.contains("-demoData") else {
            return
        }

        let calendar = Calendar.current
        let today = Date()

        func daysFromNow(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: days, to: today) ?? today
        }

        let demoMedicines: [AppMedicine] = [
            AppMedicine(
                name: "布洛芬缓释胶囊",
                expiryDate: daysFromNow(3),
                location: "客厅药箱上层",
                quantity: 2
            ),
            AppMedicine(
                name: "感冒灵颗粒",
                expiryDate: daysFromNow(9),
                location: "厨房抽屉第一格",
                quantity: 1
            ),
            AppMedicine(
                name: "氯雷他定片",
                expiryDate: daysFromNow(12),
                location: "卧室床头柜",
                quantity: 1
            ),
            AppMedicine(
                name: "阿莫西林胶囊",
                expiryDate: daysFromNow(18),
                location: "药箱第二层",
                quantity: 3
            ),
            AppMedicine(
                name: "蒙脱石散",
                expiryDate: daysFromNow(25),
                location: "儿童房小药箱",
                quantity: 2
            ),
            AppMedicine(
                name: "红霉素软膏",
                expiryDate: daysFromNow(31),
                location: "卫生间镜柜",
                quantity: 1
            ),
            AppMedicine(
                name: "维生素C片",
                expiryDate: daysFromNow(45),
                location: "客厅药箱下层",
                quantity: 1
            ),
            AppMedicine(
                name: "云南白药气雾剂",
                expiryDate: daysFromNow(60),
                location: "鞋柜上方收纳盒",
                quantity: 1
            ),
            AppMedicine(
                name: "藿香正气水",
                expiryDate: daysFromNow(75),
                location: "冰箱门侧格",
                quantity: 4
            ),
            AppMedicine(
                name: "创可贴",
                expiryDate: daysFromNow(110),
                location: "玄关急救包",
                quantity: 10
            )
        ]

        store.medicines = demoMedicines
        store.save()
    }
}