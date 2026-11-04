import Foundation
import Combine

@MainActor
final class AppBeanStore: ObservableObject {
    @Published var beans: [AppBean] = [] {
        didSet {
            saveBeans()
        }
    }

    private let persistenceURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        persistenceURL = documents.appendingPathComponent("beans.json")
        beans = loadBeans()
    }

    // MARK: - 增删改

    func addBean(name: String, roastDate: Date, initialGrams: Double) {
        let bean = AppBean(
            id: UUID(),
            name: name,
            roastDate: roastDate,
            initialGrams: initialGrams,
            remainingGrams: initialGrams
        )
        beans.append(bean)
    }

    func updateBean(_ updatedBean: AppBean) {
        guard let index = beans.firstIndex(where: { $0.id == updatedBean.id }) else { return }
        beans[index] = updatedBean
    }

    func deleteBean(_ bean: AppBean) {
        beans.removeAll { $0.id == bean.id }
    }

    func deleteBean(id: UUID) {
        beans.removeAll { $0.id == id }
    }

    // MARK: - 剩余克数扣减

    func deductRemaining(for beanID: UUID, grams: Double) {
        guard let index = beans.firstIndex(where: { $0.id == beanID }) else { return }
        let newRemaining = max(0, beans[index].remainingGrams - grams)
        beans[index].remainingGrams = newRemaining
    }

    func bean(withID id: UUID) -> AppBean? {
        beans.first { $0.id == id }
    }

    // MARK: - 新鲜度天数

    func freshnessDays(for bean: AppBean) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: bean.roastDate)
        let end = calendar.startOfDay(for: Date())
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(0, days)
    }

    // MARK: - 排序

    func sortByFreshness() {
        beans.sort { $0.roastDate > $1.roastDate }
    }

    // MARK: - 本地持久化

    private func loadBeans() -> [AppBean] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: persistenceURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: persistenceURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([AppBean].self, from: data)
        } catch {
            return []
        }
    }

    private func saveBeans() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(beans)
            try data.write(to: persistenceURL)
        } catch {
            // 保存失败时静默处理，避免影响用户操作
        }
    }
}