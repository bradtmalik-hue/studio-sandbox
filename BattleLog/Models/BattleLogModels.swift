import Foundation
import Combine

enum BattleResult: String, Codable, CaseIterable, Identifiable {
    case win = "胜利"
    case loss = "失败"
    case draw = "平局"
    
    var id: String { rawValue }
    var displayName: String { rawValue }
}

struct BattleRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var gameName: String
    var date: Date
    var result: BattleResult
    var score: Int
    var kills: Int
    var deaths: Int
    var assists: Int
    var durationMinutes: Double
    var note: String
}

class BattleLogStore: ObservableObject {
    @Published var records: [BattleRecord] = []
    
    private let fileName = "battleLogRecords.json"
    var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }
    
    init() {
        load()
    }
    
    func add(_ record: BattleRecord) {
        records.append(record)
        save()
    }
    
    func delete(_ record: BattleRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }
    
    func delete(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        save()
    }
    
    func update(_ record: BattleRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
            save()
        }
    }
    
    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(records)
            try data.write(to: fileURL)
        } catch {
            print("保存失败: \(error.localizedDescription)")
        }
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            records = try decoder.decode([BattleRecord].self, from: data)
        } catch {
            print("读取失败: \(error.localizedDescription)")
            records = []
        }
    }
    
    var totalGames: Int { records.count }
    var wins: Int { records.filter { $0.result == .win }.count }
    var losses: Int { records.filter { $0.result == .loss }.count }
    var draws: Int { records.filter { $0.result == .draw }.count }
    var winRate: Double { totalGames > 0 ? Double(wins) / Double(totalGames) : 0 }
    var averageKills: Double { totalGames > 0 ? Double(records.reduce(0) { $0 + $1.kills }) / Double(totalGames) : 0 }
    var averageScore: Double { totalGames > 0 ? Double(records.reduce(0) { $0 + $1.score }) / Double(totalGames) : 0 }
    var bestScore: Int { records.map(\.score).max() ?? 0 }
    var lastPlayedDate: Date? { records.map(\.date).max() }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
        
        let store = BattleLogStore()
        guard store.records.isEmpty else { return }
        
        store.records = sampleRecords
        store.save()
    }
    
    private static let sampleRecords: [BattleRecord] = [
        BattleRecord(
            gameName: "王者荣耀",
            date: Date().addingTimeInterval(-86400 * 2),
            result: .win,
            score: 1560,
            kills: 8,
            deaths: 2,
            assists: 7,
            durationMinutes: 18.5,
            note: "打野节奏不错，控龙成功"
        ),
        BattleRecord(
            gameName: "英雄联盟",
            date: Date().addingTimeInterval(-86400 * 3),
            result: .loss,
            score: 980,
            kills: 5,
            deaths: 9,
            assists: 12,
            durationMinutes: 32.0,
            note: "中期团战没打好，下次注意站位"
        ),
        BattleRecord(
            gameName: "反恐精英2",
            date: Date().addingTimeInterval(-86400 * 4),
            result: .win,
            score: 2350,
            kills: 21,
            deaths: 14,
            assists: 3,
            durationMinutes: 40.2,
            note: "手枪局赢了，后期守点很稳"
        ),
        BattleRecord(
            gameName: "守望先锋",
            date: Date().addingTimeInterval(-86400 * 5),
            result: .draw,
            score: 1800,
            kills: 15,
            deaths: 6,
            assists: 10,
            durationMinutes: 15.8,
            note: "加时赛平局，坦克位扛了很多伤害"
        ),
        BattleRecord(
            gameName: "原神",
            date: Date().addingTimeInterval(-86400 * 6),
            result: .win,
            score: 1200,
            kills: 0,
            deaths: 0,
            assists: 0,
            durationMinutes: 25.0,
            note: "深渊满星，练度提升很明显"
        ),
        BattleRecord(
            gameName: "英雄联盟",
            date: Date().addingTimeInterval(-86400 * 7),
            result: .win,
            score: 1450,
            kills: 10,
            deaths: 4,
            assists: 15,
            durationMinutes: 28.6,
            note: "下路组合配合默契，赢下关键局"
        ),
        BattleRecord(
            gameName: "王者荣耀",
            date: Date().addingTimeInterval(-86400 * 8),
            result: .loss,
            score: 760,
            kills: 3,
            deaths: 7,
            assists: 5,
            durationMinutes: 16.3,
            note: "上路被针对，下次选英雄要更谨慎"
        ),
        BattleRecord(
            gameName: "绝地求生",
            date: Date().addingTimeInterval(-86400 * 9),
            result: .win,
            score: 1980,
            kills: 11,
            deaths: 1,
            assists: 2,
            durationMinutes: 29.9,
            note: "决赛圈伏地魔，最后对枪成功吃鸡"
        ),
        BattleRecord(
            gameName: "星际争霸2",
            date: Date().addingTimeInterval(-86400 * 10),
            result: .loss,
            score: 640,
            kills: 0,
            deaths: 0,
            assists: 0,
            durationMinutes: 22.4,
            note: "运营节奏慢了一拍，被一波带走"
        ),
        BattleRecord(
            gameName: "Dota 2",
            date: Date().addingTimeInterval(-86400 * 12),
            result: .win,
            score: 1700,
            kills: 9,
            deaths: 5,
            assists: 18,
            durationMinutes: 45.0,
            note: "辅助视野做得好，团队配合很流畅"
        )
    ]
}