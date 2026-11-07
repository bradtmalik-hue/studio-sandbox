import SwiftUI

struct AppPage3View: View {
    @EnvironmentObject private var store: AppStore

    @State private var participantCount: Int = 2
    @State private var defaultPayer: String = ""
    @State private var currencyCode: String = "CNY"
    @State private var showValidationAlert = false
    @State private var showSavedAlert = false

    var body: some View {
        NavigationStack {
            List {
                if store.expenses.isEmpty {
                    Section {
                        AppPage3EmptyStateView()
                    }
                }

                Section {
                    AppPage3InfoCard(
                        participantCount: participantCount,
                        payer: defaultPayer.isEmpty ? "未设置" : defaultPayer,
                        currency: currencyText
                    )
                }

                Section("记账默认值") {
                    AppPage3SettingRow(title: "参与人数", icon: "person.2.fill") {
                        Stepper(value: $participantCount, in: 1...20) {
                            Text("\(participantCount) 人")
                        }
                    }

                    AppPage3SettingRow(title: "默认付款人", icon: "person.crop.circle") {
                        TextField("例如：张三", text: $defaultPayer)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 180)
                    }

                    AppPage3SettingRow(title: "货币", icon: "yensign.circle") {
                        Picker(selection: $currencyCode) {
                            Text("人民币 ¥").tag("CNY")
                            Text("美元 $").tag("USD")
                        } label: {
                            Text(currencyText)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }

                Section {
                    Button("恢复默认设置") {
                        participantCount = 2
                        defaultPayer = "我"
                        currencyCode = "CNY"
                    }

                    Button {
                        saveSettings()
                    } label: {
                        Text("保存设置")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .disabled(defaultPayer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("设置")
            .onAppear {
                loadSettings()
            }
            .alert("无法保存", isPresented: $showValidationAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text("默认付款人不能为空")
            }
            .alert("已保存", isPresented: $showSavedAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text("新的记账默认值已生效")
            }
        }
    }

    private var currencyText: String {
        switch currencyCode {
        case "USD":
            return "美元 $"
        case "CNY":
            return "人民币 ¥"
        default:
            return currencyCode
        }
    }

    private func loadSettings() {
        participantCount = max(1, min(20, store.settings.defaultParticipantCount))
        defaultPayer = store.settings.defaultPayer
        currencyCode = store.settings.currencyCode.isEmpty ? "CNY" : store.settings.currencyCode
    }

    private func saveSettings() {
        let payer = defaultPayer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !payer.isEmpty else {
            showValidationAlert = true
            return
        }

        var updatedSettings = store.settings
        updatedSettings.defaultParticipantCount = participantCount
        updatedSettings.defaultPayer = payer
        updatedSettings.currencyCode = currencyCode
        store.settings = updatedSettings
        store.save()
        showSavedAlert = true
    }
}

private struct AppPage3InfoCard: View {
    let participantCount: Int
    let payer: String
    let currency: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "gearshape.2.fill")
                .font(.title2)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 6) {
                Text("当前默认")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(participantCount) 人 · \(payer) · \(currency)")
                    .font(.headline)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }
}

private struct AppPage3EmptyStateView: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("还没有支出记录")
                    .font(.subheadline.weight(.medium))

                Text("去「记一笔」添加第一笔聚会花费")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }
}

private struct AppPage3SettingRow<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 12) {
            Label(title, systemImage: icon)
                .foregroundStyle(.primary)

            Spacer()

            content
        }
    }
}