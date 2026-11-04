import Foundation
import Combine

class BrewLogStore: ObservableObject {
    @Published var beans: [BrewBean] = []
    @Published var entries: [BrewLogEntry] = []
    
    private let fileManager = FileManager.default
    
    private var beansFileURL: URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent("brew_beans.json")
    }
    
    private var entriesFileURL: URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent("brew_log_entries.json")
    }
    
    init() {
        loadBeans()
        loadEntries()
    }
    
    // MARK: - Bean Management
    
    func addBean(_ bean: BrewBean) {
        beans.append(bean)
        saveBeans()
    }
    
    func updateBean(_ bean: BrewBean) {
        guard let index = beans.firstIndex(where: { $0.id == bean.id }) else { return }
        beans[index] = bean
        saveBeans()
    }
    
    func deleteBean(_ bean: BrewBean) {
        beans.removeAll { $0.id == bean.id }
        saveBeans()
    }
    
    func deleteBean(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            beans.remove(at: index)
        }
        saveBeans()
    }
    
    func deleteAllBeans() {
        beans.removeAll()
        saveBeans()
    }
    
    // MARK: - Entry Management
    
    func addEntry(_ entry: BrewLogEntry) {
        entries.append(entry)
        saveEntries()
    }
    
    func deleteEntry(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            entries.remove(at: index)
        }
        saveEntries()
    }
    
    func deleteAllEntries() {
        entries.removeAll()
        saveEntries()
    }
    
    // MARK: - Persistence
    
    private func loadBeans() {
        guard let url = beansFileURL,
              fileManager.fileExists(atPath: url.path) else {
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            beans = try decoder.decode([BrewBean].self, from: data)
        } catch {
            print("BrewLogStore: failed to load beans from \(beansFileURL?.path ?? "unknown path"): \(error)")
        }
    }
    
    private func loadEntries() {
        guard let url = entriesFileURL,
              fileManager.fileExists(atPath: url.path) else {
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            entries = try decoder.decode([BrewLogEntry].self, from: data)
        } catch {
            print("BrewLogStore: failed to load entries from \(entriesFileURL?.path ?? "unknown path"): \(error)")
        }
    }
    
    private func saveBeans() {
        guard let url = beansFileURL else { return }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(beans)
            try data.write(to: url, options: .atomic)
        } catch {
            print("BrewLogStore: failed to save beans to \(url.path): \(error)")
        }
    }
    
    private func saveEntries() {
        guard let url = entriesFileURL else { return }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(entries)
            try data.write(to: url, options: .atomic)
        } catch {
            print("BrewLogStore: failed to save entries to \(url.path): \(error)")
        }
    }
}