import Foundation
import Combine

enum AppMealType: String, Codable, CaseIterable, Identifiable {
    case breakfast = "早餐"
    case lunch = "午餐"
    case dinner = "晚餐"
    case snack = "加餐"

    var id: String { rawValue }
}

struct AppFeedingRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var grams: Double
    var mealType: AppMealType
    var note: String

    init(id: UUID = UUID(), date: Date, grams: Double, mealType: AppMealType, note: String = "") {
        self.id = id
        self.date = date
        self.grams = grams
        self.mealType = mealType
        self.note = note
    }
}

struct AppCatMealStoreData: Codable {
    var records: [AppFeedingRecord]
    var targetMealsPerDay: Int
    var targetGramsPerDay: Double
}

final class AppCatMealStore: ObservableObject {
    @Published var records: [AppFeedingRecord] = []
    @Published var targetMealsPerDay: Int = 2
    @Published var targetGramsPerDay: Double = 80

    private static let fileName = "cat_meal_records.json"

    private static func fileURL() -> URL? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return dir.appendingPathComponent(fileName)
    }

    init() {
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }

    func load() {
        guard let url = Self.fileURL(),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(AppCatMealStoreData.self, from: data) else {
            return
        }
        records = decoded.records.sorted { $0.date > $1.date }
        targetMealsPerDay = decoded.targetMealsPerDay
        targetGramsPerDay = decoded.targetGramsPerDay
    }

    func save() {
        guard let url = Self.fileURL() else { return }
        let dataToSave = AppCatMealStoreData(
            records: records,
            targetMealsPerDay: targetMealsPerDay,
            targetGramsPerDay: targetGramsPerDay
        )
        do {
            let data = try JSONEncoder().encode(dataToSave)
            try data.write(to: url)
        } catch {
            // 存储失败时暂不处理，保持内存数据可用
        }
    }

    func add(_ record: AppFeedingRecord) {
        records.append(record)
        sortRecords()
        save()
    }

    func delete(_ record: AppFeedingRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    func update(_ record: AppFeedingRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
        sortRecords()
        save()
    }

    func records(for day: Date) -> [AppFeedingRecord] {
        let cal = Calendar.current
        return records.filter { cal.isDate($0.date, inSameDayAs: day) }
    }

    func isMissed(day: Date) -> Bool {
        records(for: day).count < targetMealsPerDay
    }

    private func sortRecords() {
        records.sort { $0.date > $1.date }
    }
}

enum DemoSeed {
    static func apply(into store: AppCatMealStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }

        let cal = Calendar.current

        func makeDate(daysAgo: Int, hour: Int, minute: Int) -> Date {
            let day = cal.date(byAdding: .day, value: -daysAgo, to: Date())!
            return cal.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
        }

        let samples: [AppFeedingRecord] = [
            AppFeedingRecord(date: makeDate(daysAgo: 0, hour: 8, minute: 30), grams: 45, mealType: .breakfast, note: "胃口不错"),
            AppFeedingRecord(date: makeDate(daysAgo: 0, hour: 18, minute: 45), grams: 40, mealType: .dinner, note: "吃完了"),
            AppFeedingRecord(date: makeDate(daysAgo: 1, hour: 7, minute: 50), grams: 35, mealType: .breakfast, note: ""),
            AppFeedingRecord(date: makeDate(daysAgo: 2, hour: 8, minute: 15), grams: 40, mealType: .breakfast, note: ""),
            AppFeedingRecord(date: makeDate(daysAgo: 2, hour: 19, minute: 0), grams: 45, mealType: .dinner, note: "晚饭稍晚"),
            AppFeedingRecord(date: makeDate(daysAgo: 3, hour: 9, minute: 0), grams: 30, mealType: .breakfast, note: ""),
            AppFeedingRecord(date: makeDate(daysAgo: 3, hour: 18, minute: 0), grams: 50, mealType: .dinner, note: ""),
            AppFeedingRecord(date: makeDate(daysAgo: 4, hour: 8, minute: 0), grams: 45, mealType: .breakfast, note: ""),
            AppFeedingRecord(date: makeDate(daysAgo: 5, hour: 7, minute: 30), grams: 40, mealType: .breakfast, note: "起床晚了一点"),
            AppFeedingRecord(date: makeDate(daysAgo: 5, hour: 19, minute: 30), grams: 45, mealType: .dinner, note: "")
        ]

        store.records = samples.sorted { $0.date > $1.date }
        store.targetMealsPerDay = 2
        store.targetGramsPerDay = 80
        store.save()
    }
}