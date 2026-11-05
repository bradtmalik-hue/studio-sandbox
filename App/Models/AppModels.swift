import Foundation
import SwiftUI
import Combine

struct AppLens: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var brand: String
    var focalLength: String
    var aperture: String
    var purchasePrice: Double
    var condition: String
    var purchaseDate: Date
    var notes: String
    
    init(
        id: UUID = UUID(),
        name: String = "",
        brand: String = "",
        focalLength: String = "",
        aperture: String = "",
        purchasePrice: Double = 0,
        condition: String = "良好",
        purchaseDate: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.focalLength = focalLength
        self.aperture = aperture
        self.purchasePrice = purchasePrice
        self.condition = condition
        self.purchaseDate = purchaseDate
        self.notes = notes
    }
}

class AppStore: ObservableObject {
    @Published var lenses: [AppLens] = []
    
    private static let filename = "lenses.json"
    
    private var saveURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Self.filename)
    }
    
    init() {
        load()
    }
    
    func add(_ lens: AppLens) {
        lenses.append(lens)
        save()
    }
    
    func deleteLenses(at offsets: IndexSet) {
        lenses.remove(atOffsets: offsets)
        save()
    }
    
    func update(_ lens: AppLens) {
        if let index = lenses.firstIndex(where: { $0.id == lens.id }) {
            lenses[index] = lens
            save()
        }
    }
    
    var totalInvestment: Double {
        lenses.reduce(0) { $0 + $1.purchasePrice }
    }
    
    var averagePrice: Double {
        guard !lenses.isEmpty else { return 0 }
        return totalInvestment / Double(lenses.count)
    }
    
    var lensCount: Int {
        lenses.count
    }
    
    private func save() {
        guard let data = try? JSONEncoder().encode(lenses) else { return }
        do {
            try data.write(to: saveURL)
        } catch {
            print("保存镜头数据失败: \(error)")
        }
    }
    
    private func load() {
        guard let data = try? Data(contentsOf: saveURL) else { return }
        do {
            lenses = try JSONDecoder().decode([AppLens].self, from: data)
        } catch {
            print("加载镜头数据失败: \(error)")
        }
    }
}