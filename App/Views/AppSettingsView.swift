import SwiftUI

struct AppSettingsView: View {
    @AppStorage("app.language") private var languagePreference: String = "system"
    @AppStorage("app.usesMetricUnits") private var usesMetricUnits: Bool = true

    private var effectiveLanguageIsChinese: Bool {
        switch languagePreference {
        case "zh": return true
        case "en": return false
        default:
            let code = Locale.current.language.languageCode?.identifier ?? "en"
            return code == "zh"
        }
    }

    private var languageSectionHeader: String {
        effectiveLanguageIsChinese ? "偏好设置" : "Preferences"
    }

    private var languagePickerLabel: String {
        effectiveLanguageIsChinese ? "语言" : "Language"
    }

    private var languageFooter: String {
        effectiveLanguageIsChinese
            ? "选择应用显示语言。其他页面将在重启后更新。"
            : "Choose app display language. Other pages will update after restart."
    }

    private var unitsToggleLabel: String {
        effectiveLanguageIsChinese ? "使用公制单位" : "Use Metric Units"
    }

    private var aboutHeader: String {
        effectiveLanguageIsChinese ? "关于" : "About"
    }

    private var versionLabel: String {
        effectiveLanguageIsChinese ? "版本" : "Version"
    }

    private var dataStorageLabel: String {
        effectiveLanguageIsChinese ? "数据存储" : "Data Storage"
    }

    private var dataStorageValue: String {
        effectiveLanguageIsChinese ? "本地 JSON 文件（文档目录）" : "Local JSON File (Documents)"
    }

    private var developerLabel: String {
        effectiveLanguageIsChinese ? "开发者" : "Developer"
    }

    private var navigationTitleText: String {
        effectiveLanguageIsChinese ? "设置" : "Settings"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker(selection: $languagePreference, label: Text(languagePickerLabel)) {
                        Text(effectiveLanguageIsChinese ? "跟随系统" : "System").tag("system")
                        Text("中文").tag("zh")
                        Text("English").tag("en")
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text(languageSectionHeader)
                } footer: {
                    Text(languageFooter)
                }

                Section {
                    Toggle(isOn: $usesMetricUnits) {
                        Text(unitsToggleLabel)
                    }
                } header: {
                    Text(effectiveLanguageIsChinese ? "单位" : "Units")
                }

                Section {
                    LabeledContent(versionLabel, value: "1.0")
                    LabeledContent(dataStorageLabel, value: dataStorageValue)
                    LabeledContent(developerLabel, value: "App Team")
                } header: {
                    Text(aboutHeader)
                }
            }
            .navigationTitle(navigationTitleText)
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }
}

#Preview {
    AppSettingsView()
}