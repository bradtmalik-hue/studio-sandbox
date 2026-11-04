import Foundation

enum AppPersistenceError: LocalizedError {
    case documentsDirectoryUnavailable
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .documentsDirectoryUnavailable:
            return "无法访问文稿目录。"
        case .fileNotFound(let fileName):
            return "找不到本地文件：\(fileName)"
        }
    }
}

enum AppPersistence {
    private enum FileName {
        static let beans = "app_beans.json"
        static let brewRecords = "app_brew_records.json"
    }

    private static func documentsDirectory() throws -> URL {
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw AppPersistenceError.documentsDirectoryUnavailable
        }
        return directory
    }

    static func fileURL(for fileName: String) throws -> URL {
        let directory = try documentsDirectory()
        return directory.appendingPathComponent(fileName)
    }

    static func loadBeans() throws -> [AppBean] {
        try load([AppBean].self, from: FileName.beans)
    }

    static func saveBeans(_ beans: [AppBean]) throws {
        try save(beans, to: FileName.beans)
    }

    static func loadBrewRecords() throws -> [AppBrewRecord] {
        try load([AppBrewRecord].self, from: FileName.brewRecords)
    }

    static func saveBrewRecords(_ records: [AppBrewRecord]) throws {
        try save(records, to: FileName.brewRecords)
    }

    private static func load<T: Decodable>(_ type: T.Type, from fileName: String) throws -> T {
        let url = try fileURL(for: fileName)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AppPersistenceError.fileNotFound(fileName)
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    private static func save<T: Encodable>(_ value: T, to fileName: String) throws {
        let url = try fileURL(for: fileName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        try data.write(to: url)
    }
}