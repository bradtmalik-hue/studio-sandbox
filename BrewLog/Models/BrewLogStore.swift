import Foundation
import Combine

struct BrewLogWeeklyStat: Identifiable {
    var id: Date { date }
    let date: Date
    let averageRatio: Double
    let cupCount: Int
}

final class BrewLogStore: ObservableObject {
    @Published var beans: [BrewLogBean] = []
    @Published var sessions: [BrewLogSession] = []

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var beansURL: URL {
        documentsDirectory.appendingPathComponent("brewlog_beans.json")
    }

    private var sessionsURL: URL {
        documentsDirectory.appendingPathComponent("brewlog_sessions.json")
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    init() {
        loadBeans()
        loadSessions()
    }

    // MARK: - Beans

    func addBean(_ bean: BrewLogBean) {
        beans.append(bean)
        saveBeans()
    }

    func updateBean(_ bean: BrewLogBean) {
        guard let index = beans.firstIndex(where: { $0.id == bean.id }) else { return }
        beans[index] = bean
        saveBeans()
    }

    func deleteBean(_ bean: BrewLogBean) {
        beans.removeAll { $0.id == bean.id }
        saveBeans()
    }

    func deleteBean(at offsets: IndexSet) {
        beans.remove(atOffsets: offsets)
        saveBeans()
    }

    // MARK: - Sessions

    func addSession(_ session: BrewLogSession) {
        sessions.append(session)
        saveSessions()
    }

    func deleteSession(_ session: BrewLogSession) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }

    func deleteSession(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        saveSessions()
    }

    // MARK: - Weekly Stats

    var weeklyStats: [BrewLogWeeklyStat] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: startOfToday) }.sorted()

        return days.map { day in
            let daySessions = sessions.filter { calendar.isDate($0.date, inSameDayAs: day) }
            let totalRatio = daySessions.reduce(0) { $0 + $1.ratio }
            let averageRatio = daySessions.isEmpty ? 0 : totalRatio / Double(daySessions.count)

            return BrewLogWeeklyStat(
                date: day,
                averageRatio: averageRatio,
                cupCount: daySessions.count
            )
        }
    }

    // MARK: - Persistence

    private func loadBeans() {
        let url = beansURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            beans = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            beans = try decoder.decode([BrewLogBean].self, from: data)
        } catch {
            beans = []
            print("Failed to load beans: \(error)")
        }
    }

    private func loadSessions() {
        let url = sessionsURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            sessions = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            sessions = try decoder.decode([BrewLogSession].self, from: data)
        } catch {
            sessions = []
            print("Failed to load sessions: \(error)")
        }
    }

    private func saveBeans() {
        do {
            let data = try encoder.encode(beans)
            try data.write(to: beansURL)
        } catch {
            print("Failed to save beans: \(error)")
        }
    }

    private func saveSessions() {
        do {
            let data = try encoder.encode(sessions)
            try data.write(to: sessionsURL)
        } catch {
            print("Failed to save sessions: \(error)")
        }
    }
}