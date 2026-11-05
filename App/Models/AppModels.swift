import Foundation
import SwiftUI
import Combine

struct AppImageItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var imageName: String
    var note: String
    var isFavorite: Bool
    var addedDate: Date
    
    init(
        id: UUID = UUID(),
        title: String = "",
        imageName: String = "",
        note: String = "",
        isFavorite: Bool = false,
        addedDate: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.note = note
        self.isFavorite = isFavorite
        self.addedDate = addedDate
    }
}

class AppStore: ObservableObject {
    @Published var items: [AppImageItem] = []
    
    private let fileName = "appImageItems.json"
    
    init() {
        load()
    }
    
    func addItem(
        title: String,
        imageName: String,
        note: String = "",
        isFavorite: Bool = false
    ) {
        let newItem = AppImageItem(
            title: title,
            imageName: imageName,
            note: note,
            isFavorite: isFavorite,
            addedDate: Date()
        )
        items.append(newItem)
        save()
    }
    
    func deleteItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }
    
    func toggleFavorite(_ item: AppImageItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isFavorite.toggle()
        save()
    }
    
    func updateNote(_ item: AppImageItem, note: String) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].note = note
        save()
    }
    
    private func save() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = directory.appendingPathComponent(fileName)
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(items)
            try data.write(to: url)
        } catch {
            print("保存失败: \(error)")
        }
    }
    
    private func load() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = directory.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            items = try decoder.decode([AppImageItem].self, from: data)
        } catch {
            print("加载失败: \(error)")
        }
    }
}