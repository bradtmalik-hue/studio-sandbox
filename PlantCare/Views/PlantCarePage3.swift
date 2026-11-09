import SwiftUI
import Foundation

private let PlantCarePage3DateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateFormat = "MMM d, HH:mm"
    return formatter
}()

private let PlantCarePage3CurrencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    return formatter
}()

struct PlantCarePage3View: View {
    @EnvironmentObject var store: PlantCareStore
    var plant: PlantCarePlant?

    @State private var filterIndex = 0
    @State private var showingAddRecord = false

    private var currentPlant: PlantCarePlant? {
        if let plant = plant {
            return plant
        }
        return store.plants.first
    }

    private var filterOptions: [PlantCareCareType?] {
        [nil] + PlantCareCareType.allCases
    }

    private var filteredRecords: [PlantCareCareRecord] {
        guard let plantID = currentPlant?.id else { return [] }
        let records = store.careRecords.filter { $0.plantID == plantID }
        let selectedType = filterIndex == 0 ? nil : filterOptions[filterIndex]
        if let selectedType = selectedType {
            return records.filter { $0.type == selectedType }.sorted { $0.date > $1.date }
        } else {
            return records.sorted { $0.date > $1.date }
        }
    }

    private var latestRecordText: String {
        guard let latest = filteredRecords.first?.date else { return "None" }
        return PlantCarePage3DateFormatter.string(from: latest)
    }

    var totalAmount: Double {
        filteredRecords.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        List {
            if let plant = currentPlant {
                Section {
                    PlantCarePage3PlantCard(plant: plant)
                }

                Section {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(filteredRecords.count) records")
                                .font(.headline)
                            Text("Latest: \(latestRecordText)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(PlantCarePage3CurrencyFormatter.string(from: NSNumber(value: totalAmount)) ?? "$0.00")
                                .font(.headline)
                            Text("Total amount")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Picker("Filter", selection: $filterIndex) {
                        Text("All").tag(0)
                        ForEach(1..<filterOptions.count, id: \.self) { index in
                            Text(filterOptions[index]?.title ?? "Record").tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if filteredRecords.isEmpty {
                    Section {
                        PlantCarePage3EmptyState(
                            message: "No care records yet.",
                            actionTitle: "Log First Care",
                            action: { showingAddRecord = true }
                        )
                    }
                } else {
                    Section {
                        ForEach(filteredRecords) { record in
                            PlantCarePage3RecordRow(record: record)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        delete(record)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            } else {
                Section {
                    PlantCarePage3EmptyState(
                        message: "No plant selected. Go to All Plants and add one first.",
                        actionTitle: nil,
                        action: nil
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .contentMargins(.bottom, 96, for: .scrollContent)
        .navigationTitle("Care Details")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddRecord = true
                } label: {
                    Label("Add Record", systemImage: "plus")
                }
                .disabled(currentPlant == nil)
            }
        }
        .sheet(isPresented: $showingAddRecord) {
            if let plant = currentPlant {
                PlantCarePage3AddRecordSheet(plant: plant)
            }
        }
    }

    func delete(_ record: PlantCareCareRecord) {
        withAnimation {
            store.careRecords.removeAll { $0.id == record.id }
            store.save()
        }
    }
}

private struct PlantCarePage3PlantCard: View {
    let plant: PlantCarePlant

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(plant.name)
                    .font(.title2.bold())
                Spacer()
                Label(plant.location.isEmpty ? "Unplaced" : plant.location, systemImage: "location")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 20) {
                Label("Every \(plant.wateringIntervalDays)d", systemImage: "drop")
                    .font(.subheadline)
                if let lastWateredDate = plant.lastWateredDate {
                    Label(PlantCarePage3DateFormatter.string(from: lastWateredDate), systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let lastFertilizedDate = plant.lastFertilizedDate {
                    Label(PlantCarePage3DateFormatter.string(from: lastFertilizedDate), systemImage: "leaf")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if !plant.notes.isEmpty {
                Text(plant.notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct PlantCarePage3RecordRow: View {
    let record: PlantCareCareRecord

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.type.title)
                    .font(.headline)
                Text(PlantCarePage3DateFormatter.string(from: record.date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(PlantCarePage3CurrencyFormatter.string(from: NSNumber(value: record.amount)) ?? "$0.00")
                    .font(.headline)
                Text("Amount")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct PlantCarePage3EmptyState: View {
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

private struct PlantCarePage3AddRecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: PlantCareStore

    let plant: PlantCarePlant

    @State private var typeIndex = 0
    @State private var date = Date()
    @State private var amountText = ""
    @State private var note = ""
    @State private var showValidationAlert = false
    @State private var showDiscardAlert = false

    private var allTypes: [PlantCareCareType] {
        PlantCareCareType.allCases
    }

    private var isAmountValid: Bool {
        guard let amount = Double(amountText), amount > 0 else { return false }
        return true
    }

    private var isDirty: Bool {
        !amountText.isEmpty || !note.isEmpty || typeIndex != 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Record Type") {
                    Picker("Type", selection: $typeIndex) {
                        ForEach(0..<allTypes.count, id: \.self) { index in
                            Text(allTypes[index].title).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Details") {
                    DatePicker("Date", selection: $date, in: ...Date())
                    TextField("Amount (USD)", text: $amountText)
                        .keyboardType(.decimalPad)
                    TextField("Note", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }

                if !amountText.isEmpty && !isAmountValid {
                    Text("Amount must be a positive number.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Add Record")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if isDirty {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecord()
                    }
                    .disabled(!isAmountValid)
                }
            }
            .alert("Invalid Amount", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a positive numeric amount.")
            }
            .alert("Discard Changes?", isPresented: $showDiscardAlert) {
                Button("Keep Editing", role: .cancel) { }
                Button("Discard", role: .destructive) { dismiss() }
            } message: {
                Text("You have unsaved changes. Do you want to discard them?")
            }
        }
    }

    private func saveRecord() {
        guard let amount = Double(amountText), amount > 0 else {
            showValidationAlert = true
            return
        }
        let type = allTypes.indices.contains(typeIndex) ? allTypes[typeIndex] : allTypes[0]
        let record = PlantCareCareRecord(
            id: UUID(),
            plantID: plant.id,
            type: type,
            date: date,
            amount: amount,
            note: note
        )
        store.careRecords.append(record)
        store.save()
        dismiss()
    }
}