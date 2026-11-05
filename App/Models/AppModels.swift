import Foundation
import SwiftUI
import Combine

struct AppFilmEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var director: String
    var genre: String
    var watchedDate: Date
    var rating: Int // 0...5, 0 means unrated
    var notes: String
    var createdAt: Date

    init(id: UUID = UUID(), title: String, director: String = "", genre: String = "", watchedDate: Date = Date(), rating: Int = 0, notes: String = "", createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.director = director
        self.genre = genre
        self.watchedDate = watchedDate
        self.rating = rating
        self.notes = notes
        self.createdAt = createdAt
    }
}

class AppStore: ObservableObject {
    @Published var entries: [AppFilmEntry] = []

    private let fileName = "filmEntries.json"
    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName)
    }

    init() {
        load()
    }

    func add(_ entry: AppFilmEntry) {
        entries.append(entry)
        save()
    }

    func update(_ entry: AppFilmEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            save()
        }
    }

    func delete(_ entry: AppFilmEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            entries = try decoder.decode([AppFilmEntry].self, from: data)
        } catch {
            // If load fails, keep empty array
            entries = []
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(entries)
            try data.write(to: fileURL)
        } catch {
            // Save failed, log or ignore
            print("Failed to save film entries: \(error)")
        }
    }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
        let store = AppStore()
        guard store.entries.isEmpty else { return }
        store.entries = sampleEntries()
        store.save()
    }

    private static func sampleEntries() -> [AppFilmEntry] {
        let calendar = Calendar.current
        func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day))!
        }
        return [
            AppFilmEntry(
                title: "肖申克的救赎",
                director: "弗兰克·德拉邦特",
                genre: "剧情",
                watchedDate: date(2024, 1, 12),
                rating: 5,
                notes: "希望是美好的，也许是人间至善，而美好的事物永不消逝。"
            ),
            AppFilmEntry(
                title: "霸王别姬",
                director: "陈凯歌",
                genre: "剧情 / 爱情",
                watchedDate: date(2024, 2, 3),
                rating: 5,
                notes: "不疯魔不成活。"
            ),
            AppFilmEntry(
                title: "阿甘正传",
                director: "罗伯特·泽米吉斯",
                genre: "剧情 / 爱情",
                watchedDate: date(2024, 3, 17),
                rating: 4,
                notes: "人生就像一盒巧克力，你永远不知道下一颗是什么味道。"
            ),
            AppFilmEntry(
                title: "这个杀手不太冷",
                director: "吕克·贝松",
                genre: "剧情 / 动作",
                watchedDate: date(2024, 4, 9),
                rating: 5,
                notes: "里昂和玛蒂尔达，一段奇妙的相遇。"
            ),
            AppFilmEntry(
                title: "泰坦尼克号",
                director: "詹姆斯·卡梅隆",
                genre: "爱情 / 灾难",
                watchedDate: date(2024, 5, 21),
                rating: 4,
                notes: "You jump, I jump."
            ),
            AppFilmEntry(
                title: "千与千寻",
                director: "宫崎骏",
                genre: "动画 / 奇幻",
                watchedDate: date(2024, 6, 14),
                rating: 5,
                notes: "不要忘记自己的名字。"
            ),
            AppFilmEntry(
                title: "美丽人生",
                director: "罗伯托·贝尼尼",
                genre: "剧情 / 战争",
                watchedDate: date(2024, 7, 8),
                rating: 5,
                notes: "父爱如山，用乐观面对苦难。"
            ),
            AppFilmEntry(
                title: "盗梦空间",
                director: "克里斯托弗·诺兰",
                genre: "科幻 / 悬疑",
                watchedDate: date(2024, 8, 25),
                rating: 5,
                notes: "陀螺是否还在旋转？"
            ),
            AppFilmEntry(
                title: "星际穿越",
                director: "克里斯托弗·诺兰",
                genre: "科幻 / 冒险",
                watchedDate: date(2024, 9, 11),
                rating: 5,
                notes: "爱是唯一可以穿越时间和空间的力量。"
            ),
            AppFilmEntry(
                title: "楚门的世界",
                director: "彼得·威尔",
                genre: "剧情 / 科幻",
                watchedDate: date(2024, 10, 30),
                rating: 4,
                notes: "如果再也见不到你，祝你早安、午安、晚安。"
            ),
            AppFilmEntry(
                title: "放牛班的春天",
                director: "克里斯托夫·巴拉蒂",
                genre: "剧情 / 音乐",
                watchedDate: date(2024, 11, 18),
                rating: 5,
                notes: "音乐能打开心灵。"
            ),
            AppFilmEntry(
                title: "当幸福来敲门",
                director: "加布里尔·穆奇诺",
                genre: "剧情 / 传记",
                watchedDate: date(2024, 12, 24),
                rating: 4,
                notes: "如果你有梦想，就要守护它。"
            )
        ]
    }
}