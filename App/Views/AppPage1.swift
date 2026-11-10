import SwiftUI

struct AppPage1View: View {
    @EnvironmentObject private var store: AppDataStore

    @State private var date: Date = Date()
    @State private var type: AppMaintenanceType = .maintenance
    @State private var component: String = ""
    @State private var notes: String = ""
    @State private var odometerText: String = ""
    @State private var costText: String = ""
    @State private var durationText: String = ""
    @State private var showingSavedAlert = false

    private var isFormValid: Bool {
        guard !component.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let odometer = Double(odometerText), odometer >= 0,
              let cost = Double(costText), cost >= 0,
              let duration = Int(durationText), duration >= 0 else {
            return false
        }
        return true
    }

    var body: some View {
        NavigationStack {
            AppScreen {
                ScrollView {
                    VStack(spacing: AppTheme.spacing.s4) {
                        AppPage1HeroSection()

                        Picker("Type", selection: $type) {
                            Text("Maintenance")
                                .tag(AppMaintenanceType.maintenance)
                            Text("Replacement")
                                .tag(AppMaintenanceType.replacement)
                        }
                        .pickerStyle(.segmented)

                        AppCard {
                            VStack(spacing: AppTheme.spacing.s3) {
                                AppFieldRow(label: "Date") {
                                    DatePicker("", selection: $date, displayedComponents: .date)
                                        .labelsHidden()
                                }

                                AppFieldRow(label: "Component") {
                                    TextField("Chain, cassette, etc.", text: $component)
                                }

                                AppFieldRow(label: "Odometer (km)") {
                                    TextField("0", text: $odometerText)
                                        .keyboardType(.decimalPad)
                                }

                                AppFieldRow(label: "Cost") {
                                    TextField("0.00", text: $costText)
                                        .keyboardType(.decimalPad)
                                }

                                AppFieldRow(label: "Duration (min)") {
                                    TextField("0", text: $durationText)
                                        .keyboardType(.numberPad)
                                }

                                AppFieldRow(label: "Notes") {
                                    TextField("Optional", text: $notes, axis: .vertical)
                                        .lineLimit(3)
                                }
                            }
                        }

                        AppPrimaryButton(title: "Save Entry") {
                            save()
                        }
                        .disabled(!isFormValid)
                        .opacity(isFormValid ? 1 : 0.5)

                        if !store.records.isEmpty {
                            AppPage1RecentSection(records: Array(store.records.prefix(3)))
                        }
                    }
                    .padding(AppTheme.spacing.s4)
                    .padding(.bottom, AppTheme.spacing.s10)
                }
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        reset()
                    }
                }
            }
            .alert("Entry saved", isPresented: $showingSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The record has been added.")
            }
        }
    }

    func save() {
        guard let odometer = Double(odometerText),
              let cost = Double(costText),
              let duration = Int(durationText) else {
            return
        }

        let record = AppMaintenanceRecord(
            id: UUID(),
            date: date,
            type: type,
            component: component.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            odometerKm: odometer,
            cost: cost,
            durationMinutes: duration
        )

        store.add(record)
        store.save()
        reset()
        showingSavedAlert = true
    }

    private func reset() {
        date = Date()
        type = .maintenance
        component = ""
        notes = ""
        odometerText = ""
        costText = ""
        durationText = ""
    }
}

private struct AppPage1HeroSection: View {
    @EnvironmentObject private var store: AppDataStore

    private var lastServiceOdometer: Double {
        store.latestRecord?.odometerKm ?? 0
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.spacing.s3) {
                Text("Current Odometer")
                    .font(AppTheme.fontLabel)
                    .foregroundStyle(AppTheme.colors.dim)

                HStack(alignment: .firstTextBaseline, spacing: AppTheme.spacing.s2) {
                    Text(AppPage1Format.number(store.currentOdometer))
                        .font(AppTheme.fontNumber)
                        .foregroundStyle(AppTheme.colors.text)
                    Text("km")
                        .font(AppTheme.fontLabel)
                        .foregroundStyle(AppTheme.colors.dim)
                }

                Divider()

                HStack(spacing: AppTheme.spacing.s4) {
                    AppStatTile(
                        title: "Last Service",
                        value: AppPage1Format.shortDate(store.latestRecord?.date),
                        unit: nil,
                        icon: "clock"
                    )
                    Spacer()
                    AppStatTile(
                        title: "Since Service",
                        value: AppPage1Format.number(max(0, store.currentOdometer - lastServiceOdometer)),
                        unit: "km",
                        icon: "arrow.triangle.swap"
                    )
                }
            }
        }
    }
}

private struct AppPage1RecentSection: View {
    let records: [AppMaintenanceRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.s3) {
            Text("Recent Entries")
                .font(AppTheme.fontSection)
                .foregroundStyle(AppTheme.colors.text)

            AppCard {
                VStack(spacing: 0) {
                    ForEach(records) { record in
                        AppRowItem(
                            title: record.component,
                            subtitle: AppPage1Format.shortDate(record.date),
                            value: AppPage1Format.number(record.odometerKm) + " km",
                            icon: record.type == .maintenance ? "wrench.and.screwdriver" : "arrow.triangle.2.circlepath"
                        )
                        if record.id != records.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

private enum AppPage1Format {
    static func number(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func shortDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}