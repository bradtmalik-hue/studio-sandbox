import Foundation
import Combine

/// Local JSON storage inside the app sandbox. Survives restarts.
final class SettingsStore: ObservableObject {
    @Published private(set) var items: [SettingsItem] = []

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("settings.json")
    }

    init() { load() }

    func add(_ item: SettingsItem) {
        items.insert(item, at: 0)
        save()
    }

    func update(_ item: SettingsItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
        save()
    }

    func remove(_ item: SettingsItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    var count: Int { items.count }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([SettingsItem].self, from: data) else { return }
        items = decoded
    }
}
