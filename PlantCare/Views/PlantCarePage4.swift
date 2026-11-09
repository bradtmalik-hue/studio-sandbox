import SwiftUI
import Foundation

struct PlantCarePage4View: View {
    @EnvironmentObject var store: PlantCareStore
    @State private var name = ""
    @State private var location = ""
    @State private var intervalText = "7"
    @State private var notes = ""
    @State private var hasLastWatered = false
    @State private var hasLastFertilized = false
    @State private var lastWateredDate = Date()
    @State private var lastFertilizedDate = Date()
    @State private var showDiscardAlert = false
    @State private var activeAlert: PlantCarePage4Alert?
    @State private var alertMessage = ""
    @State private var isSaving = false

    private var intervalDays: Int {
        Int(intervalText) ?? 0
    }

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        intervalDays >= 1 && intervalDays <= 365
    }

    private var hasUnsavedChanges: Bool {
        !name.isEmpty || !location.isEmpty || !notes.isEmpty || intervalText != "7" || hasLastWatered || hasLastFertilized
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PlantCarePage4Card {
                        TextField("Plant name", text: $name)
                            .textFieldStyle(.roundedBorder)
                        TextField("Location", text: $location)
                            .textFieldStyle(.roundedBorder)
                    }
                } header: {
                    Text("Plant Details")
                }

                Section {
                    PlantCarePage4Card {
                        HStack {
                            Text("Watering Interval")
                            Spacer()
                            TextField("Days", text: $intervalText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                } header: {
                    Text("Care Schedule")
                } footer: {
                    Text("Choose a value between 1 and 365 days.")
                }

                Section {
                    Toggle("Add last watered date", isOn: $hasLastWatered)
                    if hasLastWatered {
                        DatePicker("Last Watered", selection: $lastWateredDate, displayedComponents: .date)
                    }

                    Toggle("Add last fertilized date", isOn: $hasLastFertilized)
                    if hasLastFertilized {
                        DatePicker("Last Fertilized", selection: $lastFertilizedDate, displayedComponents: .date)
                    }
                } header: {
                    Text("Care History")
                }

                Section {
                    PlantCarePage4Card {
                        TextField("Notes", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                    }
                } header: {
                    Text("Notes")
                }

                Section {
                    Button {
                        savePlant()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("Save Plant", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!isFormValid || isSaving)
                }
            }
            .navigationTitle("Add New Plant")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        if hasUnsavedChanges {
                            showDiscardAlert = true
                        } else {
                            clearFields()
                        }
                    }
                }
            }
            .alert(item: $activeAlert) { alert in
                if alert == .success {
                    return Alert(
                        title: Text("Plant Added"),
                        message: Text("Your new plant has been saved."),
                        dismissButton: .default(Text("OK"))
                    )
                } else {
                    return Alert(
                        title: Text("Unable to Save"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .confirmationDialog(
                "Discard Changes?",
                isPresented: $showDiscardAlert,
                titleVisibility: .visible
            ) {
                Button("Discard", role: .destructive) {
                    clearFields()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You have unsaved changes.")
            }
            .environment(\.locale, Locale(identifier: "en_US"))
        }
    }

    func savePlant() {
        guard isFormValid else {
            alertMessage = "Please enter a name, location, and a watering interval between 1 and 365 days."
            activeAlert = .validation
            return
        }

        isSaving = true
        let newPlant = PlantCarePlant(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            wateringIntervalDays: intervalDays,
            lastWateredDate: hasLastWatered ? lastWateredDate : nil,
            lastFertilizedDate: hasLastFertilized ? lastFertilizedDate : nil,
            notes: notes
        )

        store.plants.append(newPlant)

        do {
            let data = try JSONEncoder().encode(store.plants)
            try data.write(to: store.plantsFileURL)
            isSaving = false
            clearFields()
            activeAlert = .success
        } catch {
            if let index = store.plants.firstIndex(where: { $0.id == newPlant.id }) {
                store.plants.remove(at: index)
            }
            isSaving = false
            alertMessage = "Could not save the plant. Please try again."
            activeAlert = .validation
        }
    }

    private func clearFields() {
        name = ""
        location = ""
        intervalText = "7"
        notes = ""
        hasLastWatered = false
        hasLastFertilized = false
        lastWateredDate = Date()
        lastFertilizedDate = Date()
    }
}

enum PlantCarePage4Alert: String, Identifiable {
    case success
    case validation

    var id: String { rawValue }
}

struct PlantCarePage4Card<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct PlantCarePage4Row: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

struct PlantCarePage4Empty: View {
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "leaf")
        } description: {
            Text(message)
        }
    }
}