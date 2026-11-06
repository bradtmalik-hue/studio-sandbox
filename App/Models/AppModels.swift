import Foundation
import Combine

enum AppGender: String, Codable, CaseIterable, Identifiable {
    case male = "男"
    case female = "女"
    case unknown = "保密"
    
    var id: String { rawValue }
}

struct AppChildProfile: Codable {
    var name: String
    var birthDate: Date
    var gender: AppGender
}

struct AppGrowthRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var heightCm: Double
    var weightKg: Double
    var note: String?
    
    init(id: UUID = UUID(), date: Date, heightCm: Double, weightKg: Double, note: String? = nil) {
        self.id = id
        self.date = date
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.note = note
    }
}

final class AppStore: ObservableObject {
    @Published var profile: AppChildProfile
    @Published var records: [AppGrowthRecord]
    
    private let profileURL: URL
    private let recordsURL: URL
    
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        profileURL = docs.appendingPathComponent("child_profile.json")
        recordsURL = docs.appendingPathComponent("growth_records.json")
        
        let defaultBirth = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        self.profile = AppChildProfile(name: "我的宝贝", birthDate: defaultBirth, gender: .unknown)
        self.records = []
        
        load()
        
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }
    
    func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if FileManager.default.fileExists(atPath: profileURL.path) {
            do {
                let data = try Data(contentsOf: profileURL)
                profile = try decoder.decode(AppChildProfile.self, from: data)
            } catch {
                print("加载孩子信息失败: \(error)")
            }
        }
        
        if FileManager.default.fileExists(atPath: recordsURL.path) {
            do {
                let data = try Data(contentsOf: recordsURL)
                records = try decoder.decode([AppGrowthRecord].self, from: data)
            } catch {
                print("加载记录失败: \(error)")
            }
        }
    }
    
    func save() {
        saveProfile()
        saveRecords()
    }
    
    private func saveProfile() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(profile)
            try data.write(to: profileURL)
        } catch {
            print("保存孩子信息失败: \(error)")
        }
    }
    
    private func saveRecords() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(records)
            try data.write(to: recordsURL)
        } catch {
            print("保存记录失败: \(error)")
        }
    }
    
    func updateProfile(name: String, birthDate: Date, gender: AppGender) {
        profile = AppChildProfile(name: name, birthDate: birthDate, gender: gender)
        save()
    }
    
    func addRecord(_ record: AppGrowthRecord) {
        records.append(record)
        save()
    }
    
    func updateRecord(_ record: AppGrowthRecord) {
        if let idx = records.firstIndex(where: { $0.id == record.id }) {
            records[idx] = record
            save()
        }
    }
    
    func deleteRecord(_ record: AppGrowthRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }
    
    func deleteRecords(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        save()
    }
    
    func sortedRecords() -> [AppGrowthRecord] {
        records.sorted { $0.date < $1.date }
    }
    
    func latestRecord() -> AppGrowthRecord? {
        records.max { $0.date < $1.date }
    }
    
    func records(inLastDays days: Int) -> [AppGrowthRecord] {
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
        return records.filter { $0.date >= start }
    }
}

enum DemoSeed {
    static func apply(into store: AppStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }
        
        store.profile = AppChildProfile(
            name: "小团子",
            birthDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date(),
            gender: .male
        )
        
        let calendar = Calendar.current
        let now = Date()
        
        let sampleHeights: [Double] = [48.0, 51.2, 54.5, 57.8, 61.0, 64.5, 68.2, 71.6, 75.0, 78.3, 81.2, 84.5]
        let sampleWeights: [Double] = [3.2, 4.1, 5.0, 6.0, 7.2, 8.5, 9.8, 11.0, 12.1, 13.3, 14.2, 15.0]
        let notes = [
            "出生记录", "满月体检", "两个月啦", "百天记录", "四个月打卡",
            "半岁体检", "八个月啦", "周岁体检", "一岁半记录", "两岁体检",
            "两岁三个月", "两岁半记录"
        ]
        let monthIntervals: [Int] = [24, 22, 20, 18, 16, 14, 12, 10, 8, 6, 3, 1]
        
        for i in 0..<12 {
            let monthsAgo = monthIntervals[i]
            let date = calendar.date(byAdding: .month, value: -monthsAgo, to: now) ?? now
            let dateWithTime = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: date) ?? date
            let record = AppGrowthRecord(
                date: dateWithTime,
                heightCm: sampleHeights[i],
                weightKg: sampleWeights[i],
                note: notes[i]
            )
            store.records.append(record)
        }
        
        store.save()
    }
}