import SwiftUI
import Foundation

struct AppSettingsView: View {
    @State private var languagePreference: String = "system"
    @State private var appearancePreference: String = "system"

    private var isChinese: Bool {
        switch languagePreference {
        case "zh": return true
        case "en": return false
        default: return Locale.current.language.languageCode?.identifier == "zh"
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker(isChinese ? "语言" : "Language", selection: $languagePreference) {
                        Text(isChinese ? "跟随系统" : "System").tag("system")
                        Text("中文").tag("zh")
                        Text("English").tag("en")
                    }
                    Picker(isChinese ? "外观" : "Appearance", selection: $appearancePreference) {
                        Text(isChinese ? "跟随系统" : "System").tag("system")
                        Text(isChinese ? "浅色" : "Light").tag("light")
                        Text(isChinese ? "深色" : "Dark").tag("dark")
                    }
                } header: {
                    Text(isChinese ? "偏好设置" : "Preferences")
                }

                Section {
                    LabeledContent(isChinese ? "版本" : "Version", value: "1.0")
                } header: {
                    Text(isChinese ? "关于" : "About")
                }
            }
            .navigationTitle(isChinese ? "设置" : "Settings")
            .contentMargins(.bottom, 96, for: .scrollContent)
            .preferredColorScheme(colorSchemePreference)
        }
    }

    private var colorSchemePreference: ColorScheme? {
        switch appearancePreference {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}