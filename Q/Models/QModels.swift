import Foundation
import SwiftUI
import Combine

struct QItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var detail: String
    var category: QCategory
    var isFavorite: Bool

    init(id: UUID = UUID(), title: String, detail: String, category: QCategory = .general, isFavorite: Bool = false) {
        self.id = id
        self.title = title
        self.detail = detail
        self.category = category
        self.isFavorite = isFavorite
    }
}

enum QCategory: String, CaseIterable, Identifiable, Codable {
    case general
    case personal
    case work
    case study
    case fitness

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

struct QSection: Identifiable {
    let id: UUID
    var name: String
    var items: [QItem]

    init(id: UUID = UUID(), name: String, items: [QItem]) {
        self.id = id
        self.name = name
        self.items = items
    }
}

final class QStore: ObservableObject {
    @Published var items: [QItem]
    @Published var sections: [QSection]
    @Published var selectedCategory: QCategory?

    init() {
        let sampleItems = [
            QItem(title: "Sample Task", detail: "This is a sample item."),
            QItem(title: "Buy groceries", detail: "Milk, eggs, bread", category: .personal),
            QItem(title: "Finish report", detail: "Due Friday", category: .work),
            QItem(title: "Study SwiftUI", detail: "Read documentation", category: .study),
            QItem(title: "Workout", detail: "30 min cardio", category: .fitness)
        ]
        self.items = sampleItems
        self.sections = [
            QSection(name: "General", items: sampleItems.filter { $0.category == .general }),
            QSection(name: "Personal", items: sampleItems.filter { $0.category == .personal }),
            QSection(name: "Work", items: sampleItems.filter { $0.category == .work }),
            QSection(name: "Study", items: sampleItems.filter { $0.category == .study }),
            QSection(name: "Fitness", items: sampleItems.filter { $0.category == .fitness })
        ]
    }

    func addItem(title: String, detail: String, category: QCategory = .general) {
        let newItem = QItem(title: title, detail: detail, category: category)
        items.append(newItem)
        updateSections()
    }

    func deleteItem(_ item: QItem) {
        items.removeAll { $0.id == item.id }
        updateSections()
    }

    func toggleFavorite(_ item: QItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isFavorite.toggle()
        }
        updateSections()
    }

    func items(for category: QCategory) -> [QItem] {
        items.filter { $0.category == category }
    }

    private func updateSections() {
        sections = QCategory.allCases.map { category in
            QSection(name: category.displayName, items: items.filter { $0.category == category })
        }
    }
}
