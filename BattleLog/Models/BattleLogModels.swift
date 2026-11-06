import Foundation
import Combine

enum BattleResult: String, Codable, CaseIterable {
    case win
    case lose
    case draw

    var displayName: String {
        switch self {
        case .win:
            return "胜利"
        case .lose:
            return "失败"
        case .draw:
            return "平局"
        }
    }
}

struct BattleLogRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var gameName: String
    var date: Date
    var result: BattleResult
    var score: Int
    var note: String

    var title: String { gameName }

    var formattedDate: String {
        BattleLogFormatters.chineseDateTime.string(from: date)
    }

    init(
        id: UUID = UUID(),
        gameName: String,
        date: Date = Date(),
        result: BattleResult,
        score: Int = 0,
        note: String = ""
    ) {
        self.id = id
        self.gameName = gameName
        self.date = date
        self.result = result
        self.score = score
        self.note = note
    }
}

enum BattleLogFormatters {
    static let chineseDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()
}

final class BattleLogStore: ObservableObject {
    @Published var records: [BattleLogRecord] = []

    private let fileName = "battleRecords.json"

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    init() {
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }

    var totalGames: Int { records.count }

    var winCount: Int {
        records.filter { $0.result == .win }.count
    }

    var loseCount: Int {
        records.filter { $0.result == .lose }.count
    }

    var drawCount: Int {
        records.filter { $0.result == .draw }.count
    }

    var winRate: Double {
        guard totalGames > 0 else { return 0 }
        return Double(winCount) / Double(totalGames)
    }

    var averageScore: Double {
        guard totalGames > 0 else { return 0 }
        return Double(records.reduce(0) { $0 + $1.score }) / Double(totalGames)
    }

    var sortedRecords: [BattleLogRecord] {
        records.sorted { $0.date > $1.date }
    }

    func winRate(last gameCount: Int) -> Double {
        guard gameCount > 0 else { return 0 }
        let slice = sortedRecords.prefix(gameCount)
        guard !slice.isEmpty else { return 0 }
        return Double(slice.filter { $0.result == .win }.count) / Double(slice.count)
    }

    func add(_ record: BattleLogRecord) {
        records.append(record)
        save()
    }

    func update(_ record: BattleLogRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
        save()
    }

    func delete(_ record: BattleLogRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        save()
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(records)
            try data.write(to: fileURL)
        } catch {
            // 保存失败时保持当前内存数据，便于下次继续尝试
        }
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([BattleLogRecord].self, from: data)
            records = decoded
        } catch {
            records = []
        }
    }
}

enum DemoSeed {
    static let hour: TimeInterval = 3600
    static let day: TimeInterval = 86400

    static let demoRecords: [BattleLogRecord] = {
        let now = Date()
        return [
            BattleLogRecord(
                gameName: "星际征途",
                date: now.addingTimeInterval(-2 * Self.hour),
                result: .win,
                score: 1280,
                note: "开局顺利"
            ),
            BattleLogRecord(
                gameName: "幻境冒险",
                date: now.addingTimeInterval(-26 * Self.hour),
                result: .lose,
                score: 850,
                note: "团战没跟上"
            ),
            BattleLogRecord(
                gameName: "极限竞速",
                date: now.addingTimeInterval(-1 * Self.day - 3 * Self.hour),
                result: .win,
                score: 1540,
                note: "刷新个人纪录"
            ),
            BattleLogRecord(
                gameName: "火箭联盟",
                date: now.addingTimeInterval(-2 * Self.day - 1 * Self.hour),
                result: .draw,
                score: 960,
                note: "加时赛"
            ),
            BattleLogRecord(
                gameName: "魔法学院",
                date: now.addingTimeInterval(-3 * Self.day - 4 * Self.hour),
                result: .win,
                score: 1010,
                note: "输出最高"
            ),
            BattleLogRecord(
                gameName: "枪火前线",
                date: now.addingTimeInterval(-3 * Self.day - 7 * Self.hour),
                result: .lose,
                score: 420,
                note: "队友掉线"
            ),
            BattleLogRecord(
                gameName: "棋艺对决",
                date: now.addingTimeInterval(-4 * Self.day - 2 * Self.hour),
                result: .win,
                score: 1420,
                note: "险胜"
            ),
            BattleLogRecord(
                gameName: "卡牌战术",
                date: now.addingTimeInterval(-5 * Self.day - 5 * Self.hour),
                result: .lose,
                score: 390,
                note: "卡组被克制"
            ),
            BattleLogRecord(
                gameName: "足球大师",
                date: now.addingTimeInterval(-6 * Self.day - 2 * Self.hour),
                result: .win,
                score: 2100,
                note: "帽子戏法"
            ),
            BattleLogRecord(
                gameName: "篮球世界",
                date: now.addingTimeInterval(-7 * Self.day - 6 * Self.hour),
                result: .lose,
                score: 780,
                note: "最后时刻失误"
            ),
            BattleLogRecord(
                gameName: "星际征途",
                date: now.addingTimeInterval(-8 * Self.day - 3 * Self.hour),
                result: .win,
                score: 1320,
                note: "三连胜"
            ),
            BattleLogRecord(
                gameName: "幻境冒险",
                date: now.addingTimeInterval(-9 * Self.day - 8 * Self.hour),
                result: .lose,
                score: 610,
                note: "BOSS 战失败"
            )
        ]
    }()

    static func apply(into store: BattleLogStore? = nil) {
        guard let store = store, CommandLine.arguments.contains("-demoData") else {
            return
        }

        store.records = demoRecords
        store.save()
    }
}