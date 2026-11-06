import Foundation
import Combine

enum AppGender: String, Codable, CaseIterable, Identifiable {
    case male = "男孩"
    case female = "女孩"
    case unknown = "未知"

    var id: String { rawValue }
}

enum ChartMetric: String, Codable, CaseIterable, Identifiable {
    case height = "身高"
    case weight = "体重"

    var id: String { rawValue }
}

struct AppChildProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var birthDate: Date
    var gender: AppGender

    init(id: UUID = UUID(), name: String, birthDate: Date, gender: AppGender) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
    }

    var ageText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.year, .month]
        formatter.unitsStyle = .short
        formatter.maximumUnitCount = 2
        return formatter.string(from: birthDate, to: Date()) ?? "--"
    }
}

struct AppGrowthRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var childID: UUID
    var date: Date
    var height: Double?
    var weight: Double?

    init(id: UUID = UUID(), childID: UUID, date: Date = Date(), height: Double? = nil, weight: Double? = nil) {
        self.id = id
        self.childID = childID
        self.date = date
        self.height = height
        self.weight = weight
    }
}

final class AppStore: ObservableObject {
    @Published var children: [AppChildProfile] = []
    @Published var records: [AppGrowthRecord] = []

    var sortedRecords: [AppGrowthRecord] {
        records.sorted { $0.date > $1.date }
    }

    var latestRecords: [AppGrowthRecord] {
        var latest: [AppGrowthRecord] = []
        for child in children {
            if let record = sortedRecords.first(where: { $0.childID == child.id }) {
                latest.append(record)
            }
        }
        return latest.sorted { $0.date > $1.date }
    }

    func records(for childID: UUID) -> [AppGrowthRecord] {
        sortedRecords.filter { $0.childID == childID }
    }

    func latestRecord(for childID: UUID) -> AppGrowthRecord? {
        sortedRecords.first { $0.childID == childID }
    }

    func child(with id: UUID) -> AppChildProfile? {
        children.first { $0.id == id }
    }

    func addChild(_ child: AppChildProfile) {
        children.append(child)
    }

    func updateChild(_ child: AppChildProfile) {
        guard let index = children.firstIndex(where: { $0.id == child.id }) else { return }
        children[index] = child
    }

    func deleteChild(_ child: AppChildProfile) {
        guard let index = children.firstIndex(where: { $0.id == child.id }) else { return }
        children.remove(at: index)
        records.removeAll { $0.childID == child.id }
    }

    func deleteChild(at offsets: IndexSet) {
        let ids = offsets.map { children[$0].id }
        for index in offsets.sorted(by: >) {
            children.remove(at: index)
        }
        records.removeAll { ids.contains($0.childID) }
    }

    func addRecord(_ record: AppGrowthRecord) {
        records.append(record)
    }

    func updateRecord(_ record: AppGrowthRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
    }

    func deleteRecord(_ record: AppGrowthRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records.remove(at: index)
    }

    func deleteRecord(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            records.remove(at: index)
        }
    }
}

enum DemoSeed {
    static let store: AppStore = AppStore()
}