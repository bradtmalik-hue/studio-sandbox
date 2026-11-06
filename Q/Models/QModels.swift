import Foundation
import Combine

// MARK: - 数据模型

struct QHero: Codable, Identifiable {
    let id: UUID
    var name: String
    var title: String
    var weapon: String
    var rarity: Int
    var attack: Int
    var defense: Int
    var speed: Int
    var isUnlocked: Bool
}

struct QLevel: Codable, Identifiable {
    let id: UUID
    var order: Int
    var name: String
    var difficulty: Int
    var bestStars: Int
    var isCompleted: Bool
}

struct QBattleRecord: Codable, Identifiable {
    let id: UUID
    var date: Date
    var levelName: String
    var heroName: String
    var score: Int
    var stars: Int
    var duration: TimeInterval

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    var displayDate: String {
        Self.dateFormatter.string(from: date)
    }
}

// MARK: - 统一存储数据

struct QGameData: Codable {
    var heroes: [QHero]
    var levels: [QLevel]
    var battleRecords: [QBattleRecord]
}

// MARK: - 游戏数据存储

class QGameStore: ObservableObject {
    @Published var heroes: [QHero] = []
    @Published var levels: [QLevel] = []
    @Published var battleRecords: [QBattleRecord] = []

    private let fileName = "q_dynasty_slash_data.json"
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

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        if let decoded = try? decoder.decode(QGameData.self, from: data) {
            heroes = decoded.heroes
            levels = decoded.levels
            battleRecords = decoded.battleRecords
        }
    }

    func save() {
        let data = QGameData(heroes: heroes, levels: levels, battleRecords: battleRecords)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        if let encoded = try? encoder.encode(data) {
            try? encoded.write(to: fileURL)
        }
    }
}

// MARK: - 演示数据

enum DemoSeed {
    static func apply(into store: QGameStore) {
        // 武将演示数据（10条）
        let heroes: [QHero] = [
            QHero(id: UUID(), name: "赵云", title: "常山赵子龙", weapon: "龙胆亮银枪", rarity: 5, attack: 96, defense: 88, speed: 92, isUnlocked: true),
            QHero(id: UUID(), name: "关羽", title: "武圣", weapon: "青龙偃月刀", rarity: 5, attack: 98, defense: 95, speed: 80, isUnlocked: true),
            QHero(id: UUID(), name: "张飞", title: "燕人张翼德", weapon: "丈八蛇矛", rarity: 4, attack: 97, defense: 90, speed: 76, isUnlocked: true),
            QHero(id: UUID(), name: "马超", title: "锦马超", weapon: "虎头湛金枪", rarity: 4, attack: 94, defense: 82, speed: 91, isUnlocked: true),
            QHero(id: UUID(), name: "黄忠", title: "老当益壮", weapon: "麒麟弓", rarity: 4, attack: 91, defense: 78, speed: 70, isUnlocked: true),
            QHero(id: UUID(), name: "诸葛亮", title: "卧龙", weapon: "羽扇", rarity: 5, attack: 85, defense: 70, speed: 65, isUnlocked: true),
            QHero(id: UUID(), name: "吕布", title: "飞将", weapon: "方天画戟", rarity: 5, attack: 100, defense: 92, speed: 95, isUnlocked: false),
            QHero(id: UUID(), name: "貂蝉", title: "闭月", weapon: "双剑", rarity: 3, attack: 75, defense: 60, speed: 85, isUnlocked: false),
            QHero(id: UUID(), name: "曹操", title: "乱世奸雄", weapon: "倚天剑", rarity: 5, attack: 90, defense: 88, speed: 82, isUnlocked: true),
            QHero(id: UUID(), name: "刘备", title: "仁德之君", weapon: "雌雄双股剑", rarity: 4, attack: 82, defense: 75, speed: 78, isUnlocked: true)
        ]

        // 关卡演示数据（10条）
        let levels: [QLevel] = [
            QLevel(id: UUID(), order: 1, name: "黄巾之乱", difficulty: 1, bestStars: 3, isCompleted: true),
            QLevel(id: UUID(), order: 2, name: "虎牢关", difficulty: 2, bestStars: 3, isCompleted: true),
            QLevel(id: UUID(), order: 3, name: "长坂坡", difficulty: 3, bestStars: 2, isCompleted: true),
            QLevel(id: UUID(), order: 4, name: "赤壁之战", difficulty: 4, bestStars: 3, isCompleted: true),
            QLevel(id: UUID(), order: 5, name: "华容道", difficulty: 2, bestStars: 3, isCompleted: true),
            QLevel(id: UUID(), order: 6, name: "定军山", difficulty: 3, bestStars: 2, isCompleted: true),
            QLevel(id: UUID(), order: 7, name: "汉中争夺战", difficulty: 4, bestStars: 2, isCompleted: false),
            QLevel(id: UUID(), order: 8, name: "五丈原", difficulty: 5, bestStars: 0, isCompleted: false),
            QLevel(id: UUID(), order: 9, name: "合肥之战", difficulty: 3, bestStars: 1, isCompleted: true),
            QLevel(id: UUID(), order: 10, name: "街亭之战", difficulty: 4, bestStars: 0, isCompleted: false)
        ]

        // 战斗记录演示数据（12条）
        let now = Date()
        let battleRecords: [QBattleRecord] = [
            QBattleRecord(id: UUID(), date: now.addingTimeInterval(-86400 * 1), levelName: "黄巾之乱", heroName: "赵云", score: 1200, stars: 3, duration: 45),
            QBattleRecord(id: UUID(), date: now.addingTimeInterval(-86400 * 2), levelName: "虎牢关", heroName: "关羽", score: 1500, stars: 3, duration: 60),
            QBattleRecord(id: UUID(), date: now.addingTimeInterval(-86400 * 3), levelName: "长坂坡", heroName: "张飞", score: 1800, stars: 2, duration: 90),
            QBattleRecord(id: UUID(), date: now.addingTimeInterval(-86400 * 4), levelName: "赤壁之战", heroName: "诸葛亮", score: 2000, stars: 3, duration: 120),
            QBattleRecord(id: UUID(), date: now.addingTimeInterval(-86400 * 5), levelName: "华容道", heroName: "曹操", score: 1600, stars: 3, duration: 55),
            QBattleRecord(id: UUID(), date: now.addingTimeInterval(-86400 * 6), levelName: "定军山", heroName: "黄忠", score: 1700, stars: 2, duration: 80),
            QBattleRecord(id: UUID(), date: now.addingTimeInterval(-86400 * 7), levelName: "虎牢关", heroName: "马超", score: 1400, stars: 2, duration: 50),
            QBattleRecord(id: UUID(), date: now.addingTimeInterval(-86400 * 8), levelName: "合肥之战", heroName: "刘备", score: 1100, stars: 1, duration: 70),
            QBattleRecord(id: UUID(), date: now.addingTimeInterval(-86400 * 9), levelName: "长坂坡", heroName: "赵云", score: 2100, stars: 3, duration: 85),
            QBattleRecord(id: UUID(), date: now.addingTimeInterval(-86400 * 10), levelName: "汉中争夺战", heroName: "关羽", score: 1900, stars: 2, duration: 100),
            QBattleRecord(id: UUID(), date: now.addingTimeInterval(-86400 * 11), levelName: "赤壁之战", heroName: "张飞", score: 1750, stars: 2, duration: 95),
            QBattleRecord(id: UUID(), date: now.addingTimeInterval(-86400 * 12), levelName: "黄巾之乱", heroName: "马超", score: 1300, stars: 3, duration: 40)
        ]

        store.heroes = heroes
        store.levels = levels
        store.battleRecords = battleRecords
        store.save()
    }
}