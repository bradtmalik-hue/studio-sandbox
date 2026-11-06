import Foundation
import Combine

struct AppFeedingRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var catName: String
    var foodType: String
    var amountGrams: Double
    var note: String
    var date: Date
}

final class AppStore: ObservableObject {
    @Published var feedingRecords: [AppFeedingRecord] = []
    
    private let saveKey = "feedingRecords.json"
    private var saveURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(saveKey)
    }
    
    init() {
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }
    
    func add(_ record: AppFeedingRecord) {
        feedingRecords.append(record)
        save()
    }
    
    func update(_ record: AppFeedingRecord) {
        if let index = feedingRecords.firstIndex(where: { $0.id == record.id }) {
            feedingRecords[index] = record
            save()
        }
    }
    
    func delete(at offsets: IndexSet) {
        feedingRecords.remove(atOffsets: offsets)
        save()
    }
    
    func delete(_ record: AppFeedingRecord) {
        feedingRecords.removeAll { $0.id == record.id }
        save()
    }
    
    func load() {
        let url = saveURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            feedingRecords = try decoder.decode([AppFeedingRecord].self, from: data)
        } catch {
            feedingRecords = []
            print("加载失败: \(error)")
        }
    }
    
    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(feedingRecords)
            try data.write(to: saveURL)
        } catch {
            print("保存失败: \(error)")
        }
    }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
        // 实际演示数据注入由 AppStore.init 调用 apply(into:) 完成，避免重复写入。
    }
    
    static func apply(into store: AppStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let cats = ["咪咪", "灰灰", "橘橘"]
        let foods = ["鸡肉冻干", "三文鱼", "牛肉泥", "全价猫粮", "羊奶", "金枪鱼罐头"]
        let notes = ["胃口很好", "吃了一半", "加了点温水", "准时喂食", "有点挑食", "", "吃完就睡", "被叫醒喂的"]
        
        var records: [AppFeedingRecord] = []
        for dayOffset in 0..<10 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let hour = dayOffset % 2 == 0 ? 8 : 19
            let minute = dayOffset % 3 == 0 ? 0 : 30
            guard let feedDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) else { continue }
            let amount = Double(25 + (dayOffset * 7) % 20)
            let cat = cats[dayOffset % cats.count]
            let food = foods[dayOffset % foods.count]
            let note = notes[dayOffset % notes.count]
            let record = AppFeedingRecord(
                id: UUID(),
                catName: cat,
                foodType: food,
                amountGrams: amount,
                note: note,
                date: feedDate
            )
            records.append(record)
        }
        
        store.feedingRecords = records
        store.save()
    }
}