import Foundation
import Combine

enum QGeneralStyle: String, Codable, CaseIterable, Identifiable {
    case balanced
    case speed
    case aggressive
    case defensive
    case mystical

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .balanced: return "均衡"
        case .speed: return "疾风"
        case .aggressive: return "猛攻"
        case .defensive: return "坚守"
        case .mystical: return "奇术"
        }
    }

    var iconName: String {
        switch self {
        case .balanced: return "circle.grid.cross.fill"
        case .speed: return "bolt.fill"
        case .aggressive: return "flame.fill"
        case .defensive: return "shield.fill"
        case .mystical: return "sparkles"
        }
    }
}

enum QBattleOutcome: String, Codable, CaseIterable, Identifiable {
    case victory
    case defeat
    case draw

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .victory: return "胜利"
        case .defeat: return "败北"
        case .draw: return "平局"
        }
    }
}

struct QGeneral: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var style: QGeneralStyle
    var avatarSystemName: String
    var level: Int
    var power: Int
    var runs: Int
    var wins: Int
    var isUnlocked: Bool
    var skillName: String
    var skillDescription: String
}

final class QStore: ObservableObject {
    @Published var generals: [QGeneral] = []

    static var shared: QStore?

    private let generalsKey = "QStore.generals"

    init() {
        Self.shared = self
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply()
        }
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: generalsKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([QGeneral].self, from: data)
            generals = decoded
        } catch {
            generals = []
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(generals)
            UserDefaults.standard.set(data, forKey: generalsKey)
        } catch {
            // Ignore encoding failures.
        }
    }
}

typealias QGeneralStore = QStore

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
        guard let store = QStore.shared else { return }

        store.generals = [
            QGeneral(
                name: "赵云",
                style: .speed,
                avatarSystemName: "person.fill",
                level: 32,
                power: 9500,
                runs: 40,
                wins: 34,
                isUnlocked: true,
                skillName: "七进七出",
                skillDescription: "每次闪避后反击敌人，并短暂提升自身速度。"
            ),
            QGeneral(
                name: "白起",
                style: .aggressive,
                avatarSystemName: "flame.fill",
                level: 38,
                power: 11200,
                runs: 52,
                wins: 44,
                isUnlocked: true,
                skillName: "杀神军势",
                skillDescription: "进入战斗时降低敌方全体士气。"
            ),
            QGeneral(
                name: "韩信",
                style: .balanced,
                avatarSystemName: "star.fill",
                level: 35,
                power: 10300,
                runs: 48,
                wins: 40,
                isUnlocked: true,
                skillName: "背水一战",
                skillDescription: "兵力越低伤害越高，并有几率绝地翻盘。"
            ),
            QGeneral(
                name: "岳飞",
                style: .defensive,
                avatarSystemName: "shield.fill",
                level: 36,
                power: 10800,
                runs: 50,
                wins: 43,
                isUnlocked: true,
                skillName: "精忠报国",
                skillDescription: "坚守时持续恢复兵力，并提升友军防御。"
            ),
            QGeneral(
                name: "诸葛亮",
                style: .mystical,
                avatarSystemName: "moon.stars.fill",
                level: 40,
                power: 12000,
                runs: 55,
                wins: 49,
                isUnlocked: true,
                skillName: "奇门八卦",
                skillDescription: "每场战斗可预判一次敌方行动并扰乱阵型。"
            ),
            QGeneral(
                name: "关羽",
                style: .aggressive,
                avatarSystemName: "crown.fill",
                level: 37,
                power: 11500,
                runs: 49,
                wins: 42,
                isUnlocked: true,
                skillName: "威震华夏",
                skillDescription: "首次攻击有概率令敌方陷入震慑。"
            ),
            QGeneral(
                name: "貂蝉",
                style: .mystical,
                avatarSystemName: "eye.fill",
                level: 29,
                power: 8600,
                runs: 34,
                wins: 27,
                isUnlocked: true,
                skillName: "闭月连环",
                skillDescription: "让敌方目标短暂倒戈攻击同阵营。"
            ),
            QGeneral(
                name: "吕布",
                style: .aggressive,
                avatarSystemName: "bolt.fill",
                level: 42,
                power: 12800,
                runs: 58,
                wins: 50,
                isUnlocked: true,
                skillName: "天下无双",
                skillDescription: "连续攻击同一目标时伤害逐次提升。"
            ),
            QGeneral(
                name: "花木兰",
                style: .speed,
                avatarSystemName: "leaf.fill",
                level: 31,
                power: 9100,
                runs: 38,
                wins: 32,
                isUnlocked: true,
                skillName: "代父从军",
                skillDescription: "每次击败敌人后恢复一定兵力并立即再行动。"
            ),
            QGeneral(
                name: "戚继光",
                style: .defensive,
                avatarSystemName: "shield.fill",
                level: 34,
                power: 10100,
                runs: 46,
                wins: 39,
                isUnlocked: true,
                skillName: "鸳鸯阵",
                skillDescription: "列阵后减少受到的远程伤害并进行协同反击。"
            ),
            QGeneral(
                name: "李靖",
                style: .balanced,
                avatarSystemName: "arrow.up.forward",
                level: 39,
                power: 11700,
                runs: 53,
                wins: 47,
                isUnlocked: true,
                skillName: "六军镜",
                skillDescription: "战斗开始时透视敌方弱点并提升全军命中。"
            ),
            QGeneral(
                name: "秦琼",
                style: .balanced,
                avatarSystemName: "person.fill",
                level: 33,
                power: 9800,
                runs: 44,
                wins: 37,
                isUnlocked: true,
                skillName: "门神护体",
                skillDescription: "受到致命伤害时保留一点兵力，每场触发一次。"
            )
        ]

        store.save()
    }
}