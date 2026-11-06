import Foundation
import SwiftUI

struct Task: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var notes: String
    var isCompleted: Bool
    var dueDate: Date?
    var createdAt: Date
    
    init(id: UUID = UUID(), title: String, notes: String = "", isCompleted: Bool = false, dueDate: Date? = nil, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.createdAt = createdAt
    }
}

struct Category: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var tasks: [Task]
    
    init(id: UUID = UUID(), name: String, icon: String = "folder", tasks: [Task] = []) {
        self.id = id
        self.name = name
        self.icon = icon
        self.tasks = tasks
    }
}

class Store: ObservableObject {
    @Published var categories: [Category] = []
    
    init() {
        load()
    }
    
    func addCategory(name: String, icon: String = "folder") {
        let category = Category(name: name, icon: icon)
        categories.append(category)
        save()
    }
    
    func deleteCategory(at offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
        save()
    }
    
    func addTask(to categoryID: UUID, title: String, notes: String = "", dueDate: Date? = nil) {
        guard let index = categories.firstIndex(where: { $0.id == categoryID }) else { return }
        let task = Task(title: title, notes: notes, dueDate: dueDate)
        categories[index].tasks.append(task)
        save()
    }
    
    func updateTask(categoryID: UUID, taskID: UUID, title: String, notes: String, isCompleted: Bool, dueDate: Date?) {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == categoryID }),
              let taskIndex = categories[categoryIndex].tasks.firstIndex(where: { $0.id == taskID }) else { return }
        categories[categoryIndex].tasks[taskIndex].title = title
        categories[categoryIndex].tasks[taskIndex].notes = notes
        categories[categoryIndex].tasks[taskIndex].isCompleted = isCompleted
        categories[categoryIndex].tasks[taskIndex].dueDate = dueDate
        save()
    }
    
    func toggleTask(categoryID: UUID, taskID: UUID) {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == categoryID }),
              let taskIndex = categories[categoryIndex].tasks.firstIndex(where: { $0.id == taskID }) else { return }
        categories[categoryIndex].tasks[taskIndex].isCompleted.toggle()
        save()
    }
    
    func deleteTask(categoryID: UUID, taskID: UUID) {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == categoryID }) else { return }
        categories[categoryIndex].tasks.removeAll { $0.id == taskID }
        save()
    }
    
    func moveTask(from sourceCategoryID: UUID, to destinationCategoryID: UUID, taskID: UUID) {
        guard let sourceIndex = categories.firstIndex(where: { $0.id == sourceCategoryID }),
              let destinationIndex = categories.firstIndex(where: { $0.id == destinationCategoryID }),
              let task = categories[sourceIndex].tasks.first(where: { $0.id == taskID }) else { return }
        categories[sourceIndex].tasks.removeAll { $0.id == taskID }
        categories[destinationIndex].tasks.append(task)
        save()
    }
    
    func save() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(categories)
            UserDefaults.standard.set(data, forKey: "categories")
        } catch {
            print("Save failed: \(error)")
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: "categories") else { return }
        do {
            let decoder = JSONDecoder()
            categories = try decoder.decode([Category].self, from: data)
        } catch {
            print("Load failed: \(error)")
        }
    }
}
