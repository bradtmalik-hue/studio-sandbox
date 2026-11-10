import SwiftUI
import Combine

struct AppPage4View: View {
    @EnvironmentObject var store: AppDataStore
    @State private var reminderEnabled: Bool = true
    @State private var intervalKm: Double = 1000
    @State private var lastOdometer: Double = 0
    @State private var remindBeforeKm: Double = 100
    @State private var errorMessage: String? = nil
    @State private var showSaveConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            List {
                summarySection
                settingsSection
                actionSection
            }
            .navigationTitle("Reminder Settings")
            .contentMargins(.bottom, 96, for: .scrollContent)
            .alert("Settings Saved", isPresented: $showSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your oil reminder has been updated.")
            }
            .alert(item: $errorMessage) { message in
                Alert(
                    title: Text("Invalid Input"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear(perform: loadSettings)
    }

    private var summarySection: some View {
        Section {
            AppCard {
                VStack(alignment: .leading, spacing: AppTheme.s3) {
                    Text("Maintenance Summary")
                        .font(AppTheme.fontSection)
                        .foregroundColor(AppTheme.text)
                    HStack(spacing: AppTheme.s3) {
                        AppStatTile(
                            title: "Current Odometer",
                            value: formatNumber(store.currentOdometer),
                            unit: "km"
                        )
                        AppStatTile(
                            title: "Next Oil In",
                            value: formatNumber(nextOilDistance),
                            unit: "km"
                        )
                    }
                    Text("Last oil service: \(formatNumber(store.reminderSettings.lastServiceOdometerKm)) km")
                        .font(AppTheme.fontLabel)
                        .foregroundColor(AppTheme.dim)
                }
                .padding(AppTheme.s3)
            }
        }
    }

    private var settingsSection: some View {
        Section("Oil Reminder") {
            AppFieldRow(label: "Enable oil change reminder") {
                Toggle("", isOn: $reminderEnabled)
                    .labelsHidden()
            }
            AppFieldRow(label: "Remind every") {
                Stepper(value: $intervalKm, in: 100...5000, step: 100) {
                    Text("\(Int(intervalKm)) km")
                        .foregroundColor(AppTheme.text)
                }
            }
            AppFieldRow(label: "Last service odometer") {
                TextField("km", value: $lastOdometer, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            AppFieldRow(label: "Remind before") {
                Stepper(value: $remindBeforeKm, in: 0...500, step: 10) {
                    Text("\(Int(remindBeforeKm)) km")
                        .foregroundColor(AppTheme.text)
                }
            }
        }
        .listRowBackground(AppTheme.surface)
    }

    private var actionSection: some View {
        Section {
            AppPrimaryButton("Save Settings") {
                saveSettings()
            }
            Button("Reset to Defaults") {
                resetToDefaults()
            }
            .foregroundColor(AppTheme.accent)
            .frame(maxWidth: .infinity)
        }
        .listRowBackground(AppTheme.surface)
    }

    private var nextOilDistance: Double {
        let last = store.reminderSettings.lastServiceOdometerKm
        let interval = store.reminderSettings.intervalKm
        return max(0, last + interval - store.currentOdometer)
    }

    private func loadSettings() {
        reminderEnabled = store.reminderSettings.enabled
        intervalKm = store.reminderSettings.intervalKm
        lastOdometer = store.reminderSettings.lastServiceOdometerKm
        remindBeforeKm = store.reminderSettings.remindBeforeKm
    }

    func saveSettings() {
        guard intervalKm > 0 else {
            errorMessage = "Interval must be greater than 0."
            return
        }
        guard lastOdometer >= 0 else {
            errorMessage = "Odometer cannot be negative."
            return
        }
        guard remindBeforeKm >= 0 else {
            errorMessage = "Remind before cannot be negative."
            return
        }
        let newSettings = AppReminderSettings(
            enabled: reminderEnabled,
            intervalKm: intervalKm,
            lastServiceOdometerKm: lastOdometer,
            remindBeforeKm: remindBeforeKm
        )
        store.reminderSettings = newSettings
        store.save()
        showSaveConfirmation = true
    }

    private func resetToDefaults() {
        let defaultSettings = AppReminderSettings(
            enabled: true,
            intervalKm: 1000,
            lastServiceOdometerKm: store.currentOdometer,
            remindBeforeKm: 100
        )
        store.reminderSettings = defaultSettings
        store.save()
        loadSettings()
    }

    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}

struct AppPage4SummaryCard: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.s2) {
                Text(title)
                    .font(AppTheme.fontLabel)
                    .foregroundColor(AppTheme.dim)
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.s2) {
                    Text(value)
                        .font(AppTheme.fontNumber)
                        .foregroundColor(AppTheme.text)
                    Text(unit)
                        .font(AppTheme.fontCaption)
                        .foregroundColor(AppTheme.dim)
                }
            }
            .padding(AppTheme.s3)
        }
    }
}

struct AppPage4FieldRow<Content: View>: View {
    let label: String
    let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.fontBody)
                .foregroundColor(AppTheme.text)
            Spacer()
            content
        }
        .padding(.vertical, AppTheme.s2)
    }
}