import SwiftUI
import Foundation

private struct AppSettingsData: Codable {
    var language: String = "system"
    var useDarkMode: Bool = false
}

private final class AppSettingsStore: ObservableObject {
    @Published var language: String = "system" {
        didSet { save() }
    }
    @Published var useDarkMode: Bool = false {
        didSet { save() }
    }
    
    private let fileName = "app_settings.json"
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
    
    init() {
        load()
    }
    
    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(AppSettingsData.self, from: data) else {
            return
        }
        language = decoded.language
        useDarkMode = decoded.useDarkMode
    }
    
    func save() {
        let data = AppSettingsData(language: language, useDarkMode: useDarkMode)
        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: fileURL)
        }
    }
}

struct AppSettingsView: View {
    @StateObject private var store: AppSettingsStore
    
    init() {
        _store = StateObject(wrappedValue: AppSettingsStore())
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("语言", selection: $store.language) {
                        Text("中文").tag("zh")
                        Text("English").tag("en")
                        Text("跟随系统").tag("system")
                    }
                    Toggle("深色模式", isOn: $store.useDarkMode)
                } header: {
                    Text("偏好设置")
                }
            }
            .navigationTitle("设置")
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }
}