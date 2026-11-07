import Foundation
import SwiftUI
import Combine

struct AppWorkoutEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var category: String = "力量"
    var date: Date = Date()
    var durationMinutes: Int = 30
    var calories: Int = 100
    var reps: Int = 10
    var sets: Int = 3
    var isOutdoor: Bool = false
    var notes: String = ""
    
    static let categories: [String] = ["力量", "有氧", "柔韧", "核心", "其他"]
}

struct AppWorkoutDayGroup: Identifiable {
    var id: Date { dayStart }
    let dayStart: Date
    let entries: [AppWorkoutEntry]
}

struct AppPersistedData: Codable {
    var entries: [AppWorkoutEntry]
    var weeklyGoal: Int
}

final class AppStore: ObservableObject {
    @Published var entries: [AppWorkoutEntry]
    @Published var weeklyGoal: Int
    
    private let fileName = "workouts.json"
    
    private var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }
    
    init() {
        entries = []
        weeklyGoal = 3
        load()
        if CommandLine.arguments.contains("-demoData") {
            DemoSeed.apply(into: self)
        }
    }
    
    var sortedEntries: [AppWorkoutEntry] {
        entries.sorted { $0.date > $1.date }
    }
    
    var todayEntries: [AppWorkoutEntry] {
        entries
            .filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date < $1.date }
    }
    
    var groupedEntriesByDay: [AppWorkoutDayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        return grouped.keys.sorted(by: >).map { dayStart in
            AppWorkoutDayGroup(
                dayStart: dayStart,
                entries: grouped[dayStart]!.sorted { $0.date < $1.date }
            )
        }
    }
    
    var workoutsThisWeek: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return 0
        }
        return entries.filter { weekInterval.contains($0.date) }.count
    }
    
    var weekRemaining: Int {
        max(0, weeklyGoal - workoutsThisWeek)
    }
    
    var averageDuration: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.reduce(0) { $0 + $1.durationMinutes }) / Double(entries.count)
    }
    
    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }
    
    func entries(on date: Date) -> [AppWorkoutEntry] {
        let dayStart = Calendar.current.startOfDay(for: date)
        return entries
            .filter { Calendar.current.startOfDay(for: $0.date) == dayStart }
            .sorted { $0.date < $1.date }
    }
    
    func setWeeklyGoal(_ value: Int) {
        weeklyGoal = max(1, value)
        save()
    }
    
    func save() {
        guard let url = fileURL else { return }
        do {
            let payload = AppPersistedData(entries: entries, weeklyGoal: weeklyGoal)
            let data = try JSONEncoder().encode(payload)
            try data.write(to: url)
        } catch { }
    }
    
    private func load() {
        guard let url = fileURL else { return }
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(AppPersistedData.self, from: data)
            entries = payload.entries
            weeklyGoal = payload.weeklyGoal
        } catch { }
    }
}

enum DemoSeed {
    static func apply(into store: AppStore) {
        guard CommandLine.arguments.contains("-demoData") else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        func makeDate(daysAgo: Int, hour: Int, minute: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }
        
        func makeEntry(
            title: String,
            category: String,
            daysAgo: Int,
            hour: Int,
            minute: Int,
            duration: Int,
            calories: Int,
            reps: Int,
            sets: Int,
            isOutdoor: Bool,
            notes: String
        ) -> AppWorkoutEntry {
            AppWorkoutEntry(id: UUID(), title: title, category: category, date: makeDate(daysAgo: daysAgo, hour: hour, minute: minute), durationMinutes: duration, calories: calories, reps: reps, sets: sets, isOutdoor: isOutdoor, notes: notes)
        }
        
        let demoEntries: [AppWorkoutEntry] = [
            makeEntry(
                title: "深蹲",
                category: "力量",
                daysAgo: 0,
                hour: 7,
                minute: 30,
                duration: 35,
                calories: 210,
                reps: 15,
                sets: 4,
                isOutdoor: false,
                notes: "状态不错，最后一组有点吃力"
            ),
            makeEntry(
                title: "跑步",
                category: "有氧",
                daysAgo: 0,
                hour: 18,
                minute: 20,
                duration: 40,
                calories: 320,
                reps: 0,
                sets: 0,
                isOutdoor: true,
                notes: "公园慢跑，配速稳定"
            ),
            makeEntry(
                title: "引体向上",
                category: "力量",
                daysAgo: 1,
                hour: 8,
                minute: 0,
                duration: 25,
                calories: 150,
                reps: 8,
                sets: 5,
                isOutdoor: false,
                notes: "窄距握法，背部感受明显"
            ),
            makeEntry(
                title: "平板支撑",
                category: "核心",
                daysAgo: 1,
                hour: 19,
                minute: 45,
                duration: 15,
                calories: 60,
                reps: 1,
                sets: 3,
                isOutdoor: false,
                notes: "每组坚持 60 秒"
            ),
            makeEntry(
                title: "骑行",
                category: "有氧",
                daysAgo: 2,
                hour: 17,
                minute: 30,
                duration: 55,
                calories: 410,
                reps: 0,
                sets: 0,
                isOutdoor: true,
                notes: "沿江骑行，风不大"
            ),
            makeEntry(
                title: "卧推",
                category: "力量",
                daysAgo: 3,
                hour: 7,
                minute: 50,
                duration: 30,
                calories: 180,
                reps: 10,
                sets: 4,
                isOutdoor: false,
                notes: "重量比上周加了 2.5 公斤"
            ),
            makeEntry(
                title: "瑜伽",
                category: "柔韧",
                daysAgo: 4,
                hour: 21,
                minute: 0,
                duration: 45,
                calories: 130,
                reps: 0,
                sets: 0,
                isOutdoor: false,
                notes: "睡前拉伸，肩颈舒服很多"
            ),
            makeEntry(
                title: "跳操",
                category: "有氧",
                daysAgo: 4,
                hour: 12,
                minute: 15,
                duration: 30,
                calories: 260,
                reps: 0,
                sets: 0,
                isOutdoor: false,
                notes: "跟着视频跳，强度适中"
            ),
            makeEntry(
                title: "俯卧撑",
                category: "力量",
                daysAgo: 5,
                hour: 7,
                minute: 10,
                duration: 20,
                calories: 120,
                reps: 20,
                sets: 5,
                isOutdoor: false,
                notes: "胸肌和三头肌都有感觉"
            ),
            makeEntry(
                title: "划船机",
                category: "有氧",
                daysAgo: 6,
                hour: 18,
                minute: 40,
                duration: 35,
                calories: 280,
                reps: 0,
                sets: 0,
                isOutdoor: false,
                notes: "阻力调到 5，心率控制得不错"
            )
        ]
        
        store.entries = demoEntries
        store.weeklyGoal = 5
        store.save()
    }
}