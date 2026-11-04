import Foundation

struct AppPersistence {
    static let shared = AppPersistence()

    private let fileManager: FileManager
    private let directoryURL: URL

    private var beansFileURL: URL {
        directoryURL.appendingPathComponent("coffeeBeans.json")
    }

    private var recordsFileURL: URL {
        directoryURL.appendingPathComponent("brewRecords.json")
    }

    init() {
        fileManager = FileManager.default
        directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    func loadBeans() -> [AppCoffeeBean] {
        guard fileManager.fileExists(atPath: beansFileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: beansFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([AppCoffeeBean].self, from: data)
        } catch {
            return []
        }
    }

    func saveBeans(_ beans: [AppCoffeeBean]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(beans)
        try data.write(to: beansFileURL)
    }

    func loadRecords() -> [AppBrewRecord] {
        guard fileManager.fileExists(atPath: recordsFileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: recordsFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([AppBrewRecord].self, from: data)
        } catch {
            return []
        }
    }

    func saveRecords(_ records: [AppBrewRecord]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(records)
        try data.write(to: recordsFileURL)
    }
}