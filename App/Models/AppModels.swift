import Foundation
import Combine

struct AppCatchRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var species: String
    var weightKg: Double
    var lengthCm: Double
    var date: Date
    var spot: String
    var method: String
    var note: String
}

final class AppFishingStore: ObservableObject {
    @Published var records: [AppCatchRecord] = []
    
    private static var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("fishingRecords.json")
    }
    
    init() {
        load()
        #if DEBUG
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
        #endif
    }
    
    func add(_ record: AppCatchRecord) {
        records.append(record)
        save()
    }
    
    func update(_ record: AppCatchRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
        save()
    }
    
    func delete(_ record: AppCatchRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }
    
    func save() {
        guard let url = Self.fileURL else { return }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(records)
            try data.write(to: url)
        } catch {
        }
    }
    
    private func load() {
        guard let url = Self.fileURL else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            records = try decoder.decode([AppCatchRecord].self, from: data)
        } catch {
            records = []
        }
    }
}

#if DEBUG
enum DemoSeed {
    static func apply(into store: AppFishingStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }
        let calendar = Calendar.current
        let now = Date()
        func makeDate(daysAgo: Int, hour: Int, minute: Int) -> Date {
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: now),
                  let result = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) else {
                return now
            }
            return result
        }
        let demoRecords: [AppCatchRecord] = [
            AppCatchRecord(id: UUID(), species: "草鱼", weightKg: 4.8, lengthCm: 62, date: makeDate(daysAgo: 3, hour: 6, minute: 30), spot: "东湖", method: "手竿", note: "浅滩连竿，力道很足"),
            AppCatchRecord(id: UUID(), species: "鲫鱼", weightKg: 0.9, lengthCm: 28, date: makeDate(daysAgo: 5, hour: 8, minute: 10), spot: "南山水库", method: "台钓", note: "金黄色，口很轻", isReleased: true),
            AppCatchRecord(id: UUID(), species: "鲤鱼", weightKg: 3.2, lengthCm: 54, date: makeDate(daysAgo: 7, hour: 9, minute: 20), spot: "东湖", method: "抛竿", note: "冲劲很足，溜了五分钟", isReleased: false),
            AppCatchRecord(id: UUID(), species: "鳊鱼", weightKg: 1.6, lengthCm: 38, date: makeDate(daysAgo: 10, hour: 7, minute: 40), spot: "青龙河", method: "传统钓", note: "大个体，尾巴很宽", isReleased: true),
            AppCatchRecord(id: UUID(), species: "青鱼", weightKg: 6.5, lengthCm: 75, date: makeDate(daysAgo: 12, hour: 10, minute: 5), spot: "南山水库", method: "抛竿", note: "守了三个小时，终于开口", isReleased: false),
            AppCatchRecord(id: UUID(), species: "鲢鳙", weightKg: 5.1, lengthCm: 68, date: makeDate(daysAgo: 15, hour: 14, minute: 15), spot: "东湖", method: "台钓", note: "下午口好，连上两条", isReleased: false),
            AppCatchRecord(id: UUID(), species: "黄颡鱼", weightKg: 0.4, lengthCm: 22, date: makeDate(daysAgo: 2, hour: 20, minute: 30), spot: "青龙河", method: "溪流钓", note: "夜间收获，颜色很正", isReleased: true),
            AppCatchRecord(id: UUID(), species: "黑鱼", weightKg: 2.7, lengthCm: 48, date: makeDate(daysAgo: 18, hour: 16, minute: 45), spot: "芦苇荡", method: "路亚", note: "咬口猛，雷蛙中鱼", isReleased: false),
            AppCatchRecord(id: UUID(), species: "草鱼", weightKg: 5.6, lengthCm: 68, date: makeDate(daysAgo: 20, hour: 6, minute: 50), spot: "南山水库", method: "抛竿", note: "第二条大的，手感扎实", isReleased: false),
            AppCatchRecord(id: UUID(), species: "鲫鱼", weightKg: 0.8, lengthCm: 26, date: makeDate(daysAgo: 22, hour: 7, minute: 25), spot: "东湖", method: "台钓", note: "小爆护，双飞好几次", isReleased: true)
        ]
        store.records = demoRecords
        store.save()
    }
}
#endif