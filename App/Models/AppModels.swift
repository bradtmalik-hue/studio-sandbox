import Foundation
import Combine

// MARK: - 数据模型

struct AppFeedingRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var amountGrams: Double
}

struct AppSettings: Codable, Equatable {
    var dailyGoalGrams: Double = 80.0
    var catName: String = "我的猫"
}

enum AppDailyStatus: String, CaseIterable {
    case notFed = "未喂"
    case belowGoal = "未达标"
    case metGoal = "已达标"
}

// MARK: - 持久化数据容器

private struct AppPersistentData: Codable {
    var records: [AppFeedingRecord]
    var settings: AppSettings
}

// MARK: - 数据存储

@MainActor
final class AppStore: ObservableObject {
    @Published var records: [AppFeedingRecord] = [] {
        didSet { save() }
    }
    @Published var settings = AppSettings() {
        didSet { save() }
    }
    
    private static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private static let dataFileURL = documentsDirectory.appendingPathComponent("cat_meal_log.json")
    
    init() {
        load()
    }
    
    // MARK: - 数据操作
    
    func addFeeding(date: Date, amountGrams: Double) {
        records.append(AppFeedingRecord(date: date, amountGrams: amountGrams))
    }
    
    func deleteFeeding(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
    }
    
    func deleteFeeding(id: UUID) {
        records.removeAll { $0.id == id }
    }
    
    func updateSettings(dailyGoalGrams: Double? = nil, catName: String? = nil) {
        if let dailyGoalGrams = dailyGoalGrams {
            settings.dailyGoalGrams = dailyGoalGrams
        }
        if let catName = catName {
            settings.catName = catName
        }
    }
    
    // MARK: - 查询
    
    func feedingRecords(on day: Date) -> [AppFeedingRecord] {
        records.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.date < $1.date }
    }
    
    func totalGrams(on day: Date) -> Double {
        feedingRecords(on: day).reduce(0) { $0 + $1.amountGrams }
    }
    
    func isMetGoal(on day: Date) -> Bool {
        totalGrams(on: day) >= settings.dailyGoalGrams
    }
    
    func dailyStatus(for day: Date) -> AppDailyStatus {
        let total = totalGrams(on: day)
        if total <= 0 { return .notFed }
        if total < settings.dailyGoalGrams { return .belowGoal }
        return .metGoal
    }
    
    func dailyTotals(for month: Date) -> [Date: Double] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [:] }
        var totals: [Date: Double] = [:]
        var day = calendar.startOfDay(for: monthInterval.start)
        while day < monthInterval.end {
            totals[day] = totalGrams(on: day)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = nextDay
        }
        return totals
    }
    
    // MARK: - 本地持久化
    
    private func load() {
        guard let data = try? Data(contentsOf: Self.dataFileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let persisted = try? decoder.decode(AppPersistentData.self, from: data) {
            records = persisted.records
            settings = persisted.settings
        }
    }
    
    private func save() {
        let persisted = AppPersistentData(records: records, settings: settings)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(persisted) {
            try? data.write(to: Self.dataFileURL)
        }
    }
}