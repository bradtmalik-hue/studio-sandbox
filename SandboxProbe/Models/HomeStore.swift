import Foundation
import Combine

/// Local JSON storage inside the app sandbox. Survives restarts.
final class HomeStore: ObservableObject {
    @Published private(set) var items: [HomeItem] = []

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("home.json")
    }

    init() { load() }

    func add(_ item: HomeItem) {
        items.insert(item, at: 0)
        save()
    }

    func update(_ item: HomeItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
        save()
    }

    func remove(_ item: HomeItem) {
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
              let decoded = try? JSONDecoder().decode([HomeItem].self, from: data) else { return }
        items = decoded
    }
}
