import Foundation
import Combine

enum BeanStockRecordType: String, Codable, CaseIterable, Identifiable {
    case purchase = "Purchase"
    case consumption = "Consumption"
    var id: String { rawValue }
}

struct BeanStockCoffeeBag: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    var origin: String = ""
    var roaster: String = ""
    var roastLevel: String = "Medium"
    var flavorNotes: String = ""
    var stockWeightGrams: Double = 0.0
    var capacityWeightGrams: Double = 250.0
    var purchaseDate: Date = Date()
    var openedDate: Date? = nil
    var isFavorite: Bool = false
    var fill: String = ""
}

struct BeanStockRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var bagID: UUID = UUID()
    var date: Date = Date()
    var type: BeanStockRecordType = .consumption
    var amountGrams: Double = 15.0
    var note: String = ""
    var method: String = "V60"
    var grindSize: String = "Medium"
    var waterAmountMl: Double = 250.0
    var rating: Int = 0
}

struct BeanStockData: Codable {
    var bags: [BeanStockCoffeeBag]
    var records: [BeanStockRecord]
}

class BeanStockStore: ObservableObject {
    @Published var bags: [BeanStockCoffeeBag] = []
    @Published var records: [BeanStockRecord] = []

    static let fileURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("beanstock_data.json")
    }()

    init() {
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }

    var totalBags: Int { bags.count }
    var totalStockGrams: Double { bags.reduce(0) { $0 + $1.stockWeightGrams } }
    var totalRecords: Int { records.count }

    var mostRecentRecordDate: Date? {
        records.map(\.date).max()
    }

    func save() {
        let data = BeanStockData(bags: bags, records: records)
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let encoded = try encoder.encode(data)
            try encoded.write(to: Self.fileURL)
        } catch { }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: Self.fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: Self.fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(BeanStockData.self, from: data)
            self.bags = decoded.bags
            self.records = decoded.records
        } catch { }
    }

    func addBag(_ bag: BeanStockCoffeeBag) {
        bags.append(bag)
        save()
    }

    func updateBag(_ bag: BeanStockCoffeeBag) {
        if let index = bags.firstIndex(where: { $0.id == bag.id }) {
            bags[index] = bag
            save()
        }
    }

    func deleteBag(_ bag: BeanStockCoffeeBag) {
        bags.removeAll { $0.id == bag.id }
        records.removeAll { $0.bagID == bag.id }
        save()
    }

    func addRecord(_ record: BeanStockRecord) {
        records.append(record)
        if let bagIndex = bags.firstIndex(where: { $0.id == record.bagID }) {
            applyRecordEffect(record, to: &bags[bagIndex])
        }
        save()
    }

    func updateRecord(_ record: BeanStockRecord) {
        if let recordIndex = records.firstIndex(where: { $0.id == record.id }) {
            let oldRecord = records[recordIndex]
            if let bagIndex = bags.firstIndex(where: { $0.id == oldRecord.bagID }) {
                reverseRecordEffect(oldRecord, to: &bags[bagIndex])
            }
            records[recordIndex] = record
            if let bagIndex = bags.firstIndex(where: { $0.id == record.bagID }) {
                applyRecordEffect(record, to: &bags[bagIndex])
            }
            save()
        } else {
            addRecord(record)
        }
    }

    func deleteRecord(_ record: BeanStockRecord) {
        if let recordIndex = records.firstIndex(where: { $0.id == record.id }) {
            let recordToDelete = records[recordIndex]
            if let bagIndex = bags.firstIndex(where: { $0.id == recordToDelete.bagID }) {
                reverseRecordEffect(recordToDelete, to: &bags[bagIndex])
            }
            records.remove(at: recordIndex)
            save()
        }
    }

    private func applyRecordEffect(_ record: BeanStockRecord, to bag: inout BeanStockCoffeeBag) {
        if record.type == .consumption {
            bag.stockWeightGrams -= record.amountGrams
        } else {
            bag.stockWeightGrams += record.amountGrams
        }
    }

    private func reverseRecordEffect(_ record: BeanStockRecord, to bag: inout BeanStockCoffeeBag) {
        if record.type == .consumption {
            bag.stockWeightGrams += record.amountGrams
        } else {
            bag.stockWeightGrams -= record.amountGrams
        }
    }

    func bags(matching searchText: String, category: String? = nil) -> [BeanStockCoffeeBag] {
        var filtered = bags
        if let category, !category.isEmpty, category != "All" {
            filtered = filtered.filter { $0.roastLevel == category }
        }
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.origin.localizedCaseInsensitiveContains(searchText) ||
                $0.flavorNotes.localizedCaseInsensitiveContains(searchText)
            }
        }
        return filtered
    }

    var roastLevels: [String] {
        let levels = Set(bags.map(\.roastLevel))
        return levels.sorted()
    }

    var brewingMethods: [String] {
        let methods = Set(records.map(\.method))
        return methods.sorted()
    }
}

enum DemoSeed {
    static func apply(into store: BeanStockStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }
        store.bags = []
        store.records = []

        let now = Date()
        let calendar = Calendar.current

        let bag1 = BeanStockCoffeeBag(id: UUID(), name: "Ethiopia Yirgacheffe", origin: "Ethiopia", roaster: "Blue Bottle", roastLevel: "Light", flavorNotes: "Floral, citrus, bergamot", stockWeightGrams: 180, capacityWeightGrams: 250, purchaseDate: calendar.date(byAdding: .day, value: -30, to: now)!, openedDate: calendar.date(byAdding: .day, value: -20, to: now), isFavorite: true, fill: "")
        let bag2 = BeanStockCoffeeBag(id: UUID(), name: "Colombia Huila", origin: "Colombia", roaster: "Stumptown", roastLevel: "Medium", flavorNotes: "Caramel, red apple, nutty", stockWeightGrams: 320, capacityWeightGrams: 340, purchaseDate: calendar.date(byAdding: .day, value: -18, to: now)!, openedDate: calendar.date(byAdding: .day, value: -12, to: now), isFavorite: false, fill: "")
        let bag3 = BeanStockCoffeeBag(id: UUID(), name: "Brazil Santos", origin: "Brazil", roaster: "Intelligentsia", roastLevel: "Dark", flavorNotes: "Chocolate, roasted nuts, low acidity", stockWeightGrams: 410, capacityWeightGrams: 500, purchaseDate: calendar.date(byAdding: .day, value: -12, to: now)!, openedDate: calendar.date(byAdding: .day, value: -8, to: now), isFavorite: false, fill: "")
        let bag4 = BeanStockCoffeeBag(id: UUID(), name: "Kenya AA", origin: "Kenya", roaster: "Counter Culture", roastLevel: "Light", flavorNotes: "Blackcurrant, tomato, winey", stockWeightGrams: 95, capacityWeightGrams: 250, purchaseDate: calendar.date(byAdding: .day, value: -45, to: now)!, openedDate: calendar.date(byAdding: .day, value: -40, to: now), isFavorite: true, fill: "")
        let bag5 = BeanStockCoffeeBag(id: UUID(), name: "Sumatra Mandheling", origin: "Indonesia", roaster: "Peet's Coffee", roastLevel: "Dark", flavorNotes: "Earthy, cedar, spice", stockWeightGrams: 220, capacityWeightGrams: 250, purchaseDate: calendar.date(byAdding: .day, value: -60, to: now)!, openedDate: calendar.date(byAdding: .day, value: -55, to: now), isFavorite: false, fill: "")
        let bag6 = BeanStockCoffeeBag(id: UUID(), name: "Guatemala Antigua", origin: "Guatemala", roaster: "Verve Coffee", roastLevel: "Medium", flavorNotes: "Cocoa, honey, orange zest", stockWeightGrams: 150, capacityWeightGrams: 250, purchaseDate: calendar.date(byAdding: .day, value: -22, to: now)!, openedDate: calendar.date(byAdding: .day, value: -15, to: now), isFavorite: true, fill: "")
        let bag7 = BeanStockCoffeeBag(id: UUID(), name: "Costa Rica Tarrazu", origin: "Costa Rica", roaster: "Ritual Coffee", roastLevel: "Light", flavorNotes: "Honey, apricot, clean", stockWeightGrams: 260, capacityWeightGrams: 340, purchaseDate: calendar.date(byAdding: .day, value: -10, to: now)!, openedDate: calendar.date(byAdding: .day, value: -5, to: now), isFavorite: false, fill: "")
        let bag8 = BeanStockCoffeeBag(id: UUID(), name: "Panama Geisha", origin: "Panama", roaster: "Onyx Coffee Lab", roastLevel: "Light", flavorNotes: "Jasmine, peach, bergamot", stockWeightGrams: 70, capacityWeightGrams: 100, purchaseDate: calendar.date(byAdding: .day, value: -5, to: now)!, openedDate: calendar.date(byAdding: .day, value: -3, to: now), isFavorite: true, fill: "")
        let bag9 = BeanStockCoffeeBag(id: UUID(), name: "House Blend", origin: "Ethiopia, Colombia", roaster: "Local Roaster", roastLevel: "Medium", flavorNotes: "Balanced, caramel, milk chocolate", stockWeightGrams: 500, capacityWeightGrams: 500, purchaseDate: calendar.date(byAdding: .day, value: -7, to: now)!, openedDate: calendar.date(byAdding: .day, value: -7, to: now), isFavorite: false, fill: "")
        let bag10 = BeanStockCoffeeBag(id: UUID(), name: "Espresso Blend", origin: "Brazil, Guatemala", roaster: "Sightglass", roastLevel: "Dark", flavorNotes: "Molasses, dark chocolate, syrupy", stockWeightGrams: 300, capacityWeightGrams: 340, purchaseDate: calendar.date(byAdding: .day, value: -14, to: now)!, openedDate: calendar.date(byAdding: .day, value: -10, to: now), isFavorite: true, fill: "")

        let bags = [bag1, bag2, bag3, bag4, bag5, bag6, bag7, bag8, bag9, bag10]

        let record1 = BeanStockRecord(id: UUID(), bagID: bag1.id, date: calendar.date(byAdding: .day, value: -1, to: now)!, type: .consumption, amountGrams: 18, note: "Bright and floral", method: "V60", grindSize: "Medium Fine", waterAmountMl: 300, rating: 4)
        let record2 = BeanStockRecord(id: UUID(), bagID: bag2.id, date: calendar.date(byAdding: .day, value: -2, to: now)!, type: .consumption, amountGrams: 20, note: "Smooth caramel finish", method: "Chemex", grindSize: "Medium Coarse", waterAmountMl: 320, rating: 4)
        let record3 = BeanStockRecord(id: UUID(), bagID: bag3.id, date: calendar.date(byAdding: .day, value: -3, to: now)!, type: .consumption, amountGrams: 16, note: "Bold and chocolatey", method: "Espresso", grindSize: "Fine", waterAmountMl: 36, rating: 3)
        let record4 = BeanStockRecord(id: UUID(), bagID: bag4.id, date: calendar.date(byAdding: .day, value: -4, to: now)!, type: .consumption, amountGrams: 18, note: "Intense blackcurrant", method: "V60", grindSize: "Medium Fine", waterAmountMl: 300, rating: 5)
        let record5 = BeanStockRecord(id: UUID(), bagID: bag5.id, date: calendar.date(byAdding: .day, value: -5, to: now)!, type: .consumption, amountGrams: 15, note: "Earthy and heavy", method: "French Press", grindSize: "Coarse", waterAmountMl: 250, rating: 3)
        let record6 = BeanStockRecord(id: UUID(), bagID: bag6.id, date: calendar.date(byAdding: .day, value: -6, to: now)!, type: .consumption, amountGrams: 18, note: "Honey sweetness", method: "V60", grindSize: "Medium", waterAmountMl: 300, rating: 4)
        let record7 = BeanStockRecord(id: UUID(), bagID: bag7.id, date: calendar.date(byAdding: .day, value: -7, to: now)!, type: .purchase, amountGrams: 340, note: "New bag arrival", method: "", grindSize: "", waterAmountMl: 0, rating: 0)
        let record8 = BeanStockRecord(id: UUID(), bagID: bag8.id, date: calendar.date(byAdding: .day, value: -1, to: now)!, type: .consumption, amountGrams: 15, note: "Delicate jasmine notes", method: "V60", grindSize: "Medium Fine", waterAmountMl: 250, rating: 5)
        let record9 = BeanStockRecord(id: UUID(), bagID: bag9.id, date: calendar.date(byAdding: .day, value: -2, to: now)!, type: .consumption, amountGrams: 20, note: "Comforting blend", method: "AeroPress", grindSize: "Medium", waterAmountMl: 220, rating: 4)
        let record10 = BeanStockRecord(id: UUID(), bagID: bag10.id, date: calendar.date(byAdding: .day, value: -3, to: now)!, type: .consumption, amountGrams: 19, note: "Thick crema", method: "Espresso", grindSize: "Fine", waterAmountMl: 40, rating: 4)

        store.bags = bags
        store.records = [record1, record2, record3, record4, record5, record6, record7, record8, record9, record10]
        store.save()
    }
}