import Foundation
import Combine

final class BrewLogStore: ObservableObject {
    @Published var beans: [BrewLogBean] = []
    @Published var brews: [BrewLogBrew] = []

    static let shared = BrewLogStore()

    private let fileManager: FileManager
    private let beansURL: URL
    private let brewsURL: URL

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.beansURL = documentsURL.appendingPathComponent("BrewLogBeans.json")
        self.brewsURL = documentsURL.appendingPathComponent("BrewLogBrews.json")
        load()
    }

    func addBean(_ bean: BrewLogBean) {
        beans.append(bean)
        saveBeans()
    }

    func addBrew(_ brew: BrewLogBrew) {
        brews.append(brew)
        saveBrews()
    }

    func removeBeans(at offsets: IndexSet) {
        beans.remove(atOffsets: offsets)
        saveBeans()
    }

    func removeBrews(at offsets: IndexSet) {
        brews.remove(atOffsets: offsets)
        saveBrews()
    }

    func saveBeans() {
        do {
            let data = try Self.encoder.encode(beans)
            try data.write(to: beansURL)
        } catch {
            print("Failed to save beans: \(error)")
        }
    }

    func saveBrews() {
        do {
            let data = try Self.encoder.encode(brews)
            try data.write(to: brewsURL)
        } catch {
            print("Failed to save brews: \(error)")
        }
    }

    private func load() {
        loadBeans()
        loadBrews()
    }

    private func loadBeans() {
        guard fileManager.fileExists(atPath: beansURL.path) else { return }
        do {
            let data = try Data(contentsOf: beansURL)
            let decoded = try Self.decoder.decode([BrewLogBean].self, from: data)
            beans = decoded
        } catch {
            print("Failed to load beans: \(error)")
        }
    }

    private func loadBrews() {
        guard fileManager.fileExists(atPath: brewsURL.path) else { return }
        do {
            let data = try Data(contentsOf: brewsURL)
            let decoded = try Self.decoder.decode([BrewLogBrew].self, from: data)
            brews = decoded
        } catch {
            print("Failed to load brews: \(error)")
        }
    }
}