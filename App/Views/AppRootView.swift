import SwiftUI
import Combine
import Foundation

// MARK: - App 标签页
enum AppTab: String, CaseIterable, Identifiable {
    case beans
    case brewLog
    case suggestion
    case remainingCups

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beans: return "豆子"
        case .brewLog: return "冲煮"
        case .suggestion: return "建议"
        case .remainingCups: return "剩余杯数"
        }
    }

    var iconName: String {
        switch self {
        case .beans: return "leaf.fill"
        case .brewLog: return "cup.and.saucer.fill"
        case .suggestion: return "lightbulb.fill"
        case .remainingCups: return "number.circle.fill"
        }
    }
}

// MARK: - 共享数据存储
final class AppStore: ObservableObject {
    @Published var coffeeBeans: [AppCoffeeBean] = []
    @Published var brewRecords: [AppBrewRecord] = []

    private let beansFileName = "coffeeBeans.json"
    private let recordsFileName = "brewRecords.json"
    private let fileManager = FileManager.default

    init() {
        loadBeans()
        loadRecords()
    }

    // MARK: - 豆子 CRUD
    func addBean(_ bean: AppCoffeeBean) {
        coffeeBeans.append(bean)
        saveBeans()
    }

    func updateBean(_ bean: AppCoffeeBean) {
        if let index = coffeeBeans.firstIndex(where: { $0.id == bean.id }) {
            coffeeBeans[index] = bean
            saveBeans()
        }
    }

    func deleteBean(_ bean: AppCoffeeBean) {
        coffeeBeans.removeAll { $0.id == bean.id }
        // 同时删除关联的冲煮记录，避免悬空关联
        brewRecords.removeAll { $0.beanID == bean.id }
        saveBeans()
        saveRecords()
    }

    /// 直接扣减指定豆子的剩余克数（供冲煮日志调用）
    func deductGrams(_ grams: Double, from beanID: UUID) {
        guard let index = coffeeBeans.firstIndex(where: { $0.id == beanID }) else { return }
        coffeeBeans[index].remainingGrams -= grams
        saveBeans()
    }

    // MARK: - 冲煮记录 CRUD
    func addRecord(_ record: AppBrewRecord) {
        brewRecords.append(record)
        saveRecords()
    }

    func deleteRecord(_ record: AppBrewRecord) {
        brewRecords.removeAll { $0.id == record.id }
        saveRecords()
    }

    // MARK: - 本地持久化
    private func documentsDirectory() -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func beansFileURL() -> URL {
        documentsDirectory().appendingPathComponent(beansFileName)
    }

    private func recordsFileURL() -> URL {
        documentsDirectory().appendingPathComponent(recordsFileName)
    }

    private func loadBeans() {
        let url = beansFileURL()
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([AppCoffeeBean].self, from: data) else {
            coffeeBeans = []
            return
        }
        coffeeBeans = decoded
    }

    private func loadRecords() {
        let url = recordsFileURL()
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([AppBrewRecord].self, from: data) else {
            brewRecords = []
            return
        }
        brewRecords = decoded
    }

    private func saveBeans() {
        let url = beansFileURL()
        do {
            let data = try JSONEncoder().encode(coffeeBeans)
            try data.write(to: url)
        } catch {
            // 处理写入失败（例如磁盘空间不足，但实际应用可静默或记录）
        }
    }

    private func saveRecords() {
        let url = recordsFileURL()
        do {
            let data = try JSONEncoder().encode(brewRecords)
            try data.write(to: url)
        } catch {
            // 处理写入失败
        }
    }
}

// MARK: - 入口视图
struct AppRootView: View {
    @StateObject private var store = AppStore()
    @State private var selectedTab: AppTab = .beans

    var body: some View {
        VStack(spacing: 0) {
            // 内容区域
            ZStack {
                switch selectedTab {
                case .beans:
                    BeanInventoryView()
                case .brewLog:
                    AppBrewLogView()
                case .suggestion:
                    BrewSuggestionView()
                case .remainingCups:
                    AppRemainingCupsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // 自定义底部标签栏
            customTabBar
        }
        .environmentObject(store)
    }

    private var customTabBar: some View {
        HStack {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 20))
                        Text(tab.title)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal, 8)
        .background(.background)
    }
}

#Preview {
    AppRootView()
}