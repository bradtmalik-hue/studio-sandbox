import Foundation
import Combine

enum BattleLogResult: String, Codable, CaseIterable, Identifiable {
    case win = "win"
    case loss = "loss"
    case draw = "draw"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .win: return "胜"
        case .loss: return "负"
        case .draw: return "平"
        }
    }
}

struct BattleLogMatch: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var gameName: String = ""
    var result: BattleLogResult = .loss
    var ourScore: Int = 0
    var opponentScore: Int = 0
    var notes: String = ""
}

@MainActor
final class BattleLogStore: ObservableObject {
    @Published var matches: [BattleLogMatch] = []

    static var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("battleLogMatches.json")
    }

    private let fileURL: URL

    init() {
        self.fileURL = Self.fileURL
        load()
    }

    func add(_ match: BattleLogMatch) {
        matches.append(match)
        save()
    }

    func update(_ match: BattleLogMatch) {
        guard let index = matches.firstIndex(where: { $0.id == match.id }) else { return }
        matches[index] = match
        save()
    }

    func delete(_ match: BattleLogMatch) {
        matches.removeAll { $0.id == match.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        matches.remove(atOffsets: offsets)
        save()
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try decoder.decode([BattleLogMatch].self, from: data)
            matches = decoded.sorted { $0.date > $1.date }
        } catch {
            matches = []
        }
    }

    private func save() {
        matches.sort { $0.date > $1.date }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(matches)
            try data.write(to: fileURL)
        } catch {
            // ignore for now; data stays in memory
        }
    }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
        let url = BattleLogStore.fileURL

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if FileManager.default.fileExists(atPath: url.path) {
            guard let data = try? Data(contentsOf: url),
                  let decoded = try? decoder.decode([BattleLogMatch].self, from: data) else {
                return
            }
            if !decoded.isEmpty {
                return
            }
        }

        let calendar = Calendar.current
        let now = Date()
        func date(daysAgo: Int, hour: Int = 20, minute: Int = 30) -> Date {
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }

        let samples: [BattleLogMatch] = [
            BattleLogMatch(
                date: date(daysAgo: 0, hour: 21, minute: 10),
                gameName: "王者荣耀",
                result: .win,
                ourScore: 12,
                opponentScore: 7,
                notes: "排位赛，打野节奏很好"
            ),
            BattleLogMatch(
                date: date(daysAgo: 1, hour: 20, minute: 45),
                gameName: "英雄联盟手游",
                result: .loss,
                ourScore: 8,
                opponentScore: 14,
                notes: "下路被针对，前期崩了"
            ),
            BattleLogMatch(
                date: date(daysAgo: 2, hour: 22, minute: 5),
                gameName: "金铲铲之战",
                result: .win,
                ourScore: 1,
                opponentScore: 0,
                notes: "三星五费，爽局"
            ),
            BattleLogMatch(
                date: date(daysAgo: 3, hour: 19, minute: 30),
                gameName: "和平精英",
                result: .draw,
                ourScore: 0,
                opponentScore: 0,
                notes: "决赛圈同归于尽"
            ),
            BattleLogMatch(
                date: date(daysAgo: 4, hour: 23, minute: 15),
                gameName: "炉石传说",
                result: .win,
                ourScore: 3,
                opponentScore: 1,
                notes: "控制牧内战，赢在疲劳"
            ),
            BattleLogMatch(
                date: date(daysAgo: 6, hour: 18, minute: 50),
                gameName: "皇室战争",
                result: .loss,
                ourScore: 1,
                opponentScore: 2,
                notes: "加时赛被火球斩杀"
            ),
            BattleLogMatch(
                date: date(daysAgo: 8, hour: 21, minute: 40),
                gameName: "荒野乱斗",
                result: .win,
                ourScore: 10,
                opponentScore: 5,
                notes: "足球模式，独狼发挥"
            ),
            BattleLogMatch(
                date: date(daysAgo: 10, hour: 20, minute: 20),
                gameName: "第五人格",
                result: .win,
                ourScore: 3,
                opponentScore: 1,
                notes: "监管者四杀"
            ),
            BattleLogMatch(
                date: date(daysAgo: 12, hour: 22, minute: 30),
                gameName: "部落冲突",
                result: .loss,
                ourScore: 45,
                opponentScore: 52,
                notes: "部落战差一点三星"
            ),
            BattleLogMatch(
                date: date(daysAgo: 14, hour: 19, minute: 10),
                gameName: "QQ飞车手游",
                result: .win,
                ourScore: 1,
                opponentScore: 0,
                notes: "个人竞速第一"
            )
        ]

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(samples) {
            try? data.write(to: url)
        }
    }
}