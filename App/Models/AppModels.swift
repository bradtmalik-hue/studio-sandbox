import Foundation
import Combine

struct AppQuote: Identifiable, Codable, Hashable {
    var id: UUID
    var text: String
    var source: String
    var author: String
    var page: Int
    var note: String
    var dateAdded: Date
    var category: String
    var isFavorite: Bool
    
    init(id: UUID = UUID(), text: String, source: String, author: String, page: Int = 0, note: String = "", dateAdded: Date = Date(), category: String = "未分类", isFavorite: Bool = false) {
        self.id = id
        self.text = text
        self.source = source
        self.author = author
        self.page = page
        self.note = note
        self.dateAdded = dateAdded
        self.category = category
        self.isFavorite = isFavorite
    }
}

final class AppStore: ObservableObject {
    @Published private(set) var quotes: [AppQuote] = []
    
    private let fileName = "quotes.json"
    
    init() {
        load()
    }
    
    var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }
    
    func add(_ quote: AppQuote) {
        quotes.append(quote)
        save()
    }
    
    func update(_ quote: AppQuote) {
        guard let index = quotes.firstIndex(where: { $0.id == quote.id }) else { return }
        quotes[index] = quote
        save()
    }
    
    func delete(_ quote: AppQuote) {
        quotes.removeAll { $0.id == quote.id }
        save()
    }
    
    func delete(at offsets: IndexSet) {
        quotes.remove(atOffsets: offsets)
        save()
    }
    
    func toggleFavorite(_ quote: AppQuote) {
        guard let index = quotes.firstIndex(where: { $0.id == quote.id }) else { return }
        quotes[index].isFavorite.toggle()
        save()
    }
    
    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        quotes = (try? decoder.decode([AppQuote].self, from: data)) ?? []
    }
    
    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(quotes)
            try data.write(to: fileURL)
        } catch {
            // 存储失败时保留内存中的数据，不做额外处理
        }
    }
}

enum DemoSeed {
    static func apply() {
        guard CommandLine.arguments.contains("-demoData") else { return }
        
        let store = AppStore()
        guard store.quotes.isEmpty else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        func daysAgo(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: -days, to: now) ?? now
        }
        
        store.add(AppQuote(text: "满地都是六便士，他却抬头看见了月亮。", source: "月亮与六便士", author: "毛姆", page: 1, note: "理想与现实的对比。", dateAdded: daysAgo(0), category: "文学", isFavorite: true))
        store.add(AppQuote(text: "生活不能等待别人来安排，要自己去争取和奋斗。", source: "平凡的世界", author: "路遥", page: 45, note: "主动争取。", dateAdded: daysAgo(1), category: "励志", isFavorite: false))
        store.add(AppQuote(text: "世界上只有一种真正的英雄主义，那就是在认清生活的真相后依然热爱生活。", source: "米开朗基罗传", author: "罗曼·罗兰", page: 102, note: "热爱生活。", dateAdded: daysAgo(2), category: "哲学", isFavorite: true))
        store.add(AppQuote(text: "每一个不曾起舞的日子，都是对生命的辜负。", source: "查拉图斯特拉如是说", author: "尼采", page: 77, note: "珍惜时间。", dateAdded: daysAgo(3), category: "哲学", isFavorite: false))
        store.add(AppQuote(text: "人是为了活着本身而活着，而不是为了活着之外的任何事物而活着。", source: "活着", author: "余华", page: 184, note: "活着本身。", dateAdded: daysAgo(4), category: "文学", isFavorite: true))
        store.add(AppQuote(text: "我们终此一生，就是要摆脱他人的期待，找到真正的自己。", source: "无声告白", author: "伍绮诗", page: 220, note: "找到自己。", dateAdded: daysAgo(5), category: "成长", isFavorite: false))
        store.add(AppQuote(text: "眼睛为她下着雨，心却为她打着伞，这就是爱情。", source: "吉檀迦利", author: "泰戈尔", page: 56, note: "爱情。", dateAdded: daysAgo(6), category: "情感", isFavorite: true))
        store.add(AppQuote(text: "一个人可以被毁灭，但不能被打败。", source: "老人与海", author: "海明威", page: 97, note: "坚持。", dateAdded: daysAgo(7), category: "励志", isFavorite: false))
        store.add(AppQuote(text: "我荒废了时间，时间便把我荒废了。", source: "莎士比亚十四行诗", author: "莎士比亚", page: 33, note: "时间。", dateAdded: daysAgo(8), category: "哲理", isFavorite: false))
        store.add(AppQuote(text: "如果有来生，要做一棵树，站成永恒，没有悲欢的姿势。", source: "说给自己听", author: "三毛", page: 12, note: "永恒。", dateAdded: daysAgo(9), category: "文学", isFavorite: true))
        store.add(AppQuote(text: "你微微地笑着，不同我说什么话。而我觉得，为了这个，我已等待得很久了。", source: "飞鸟集", author: "泰戈尔", page: 88, note: "等待。", dateAdded: daysAgo(10), category: "情感", isFavorite: false))
        store.add(AppQuote(text: "人生如逆旅，我亦是行人。", source: "临江仙·送钱穆父", author: "苏轼", page: 1, note: "人生。", dateAdded: daysAgo(11), category: "诗词", isFavorite: true))
    }
}