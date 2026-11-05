import SwiftUI
import Foundation

// MARK: - Plant Water Reminder List View
struct PlantWaterReminderListView: View {
    @EnvironmentObject private var store: PlantWaterReminderStore
    @State private var showingAddPlant = false
    @State private var plantToEdit: PlantWaterReminderPlant?

    var body: some View {
        NavigationStack {
            Group {
                if store.plants.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .navigationTitle("My Plants")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddPlant = true
                    } label: {
                        Label("Add Plant", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPlant) {
                PlantWaterReminderEditView(plant: nil)
            }
            .sheet(item: $plantToEdit) { plant in
                PlantWaterReminderEditView(plant: plant)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Plants", systemImage: "leaf")
        } description: {
            Text("Add your first plant to start tracking watering schedules.")
        } actions: {
            Button("Add Plant") {
                showingAddPlant = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var listContent: some View {
        List {
            if !overduePlants.isEmpty {
                Section("Overdue") {
                    ForEach(overduePlants) { plant in
                        PlantWaterReminderRow(plant: plant)
                            .swipeActions(edge: .leading) {
                                Button {
                                    waterPlant(plant)
                                } label: {
                                    Label("Watered", systemImage: "drop.fill")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.delete(plant)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    plantToEdit = plant
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
            if !dueTodayPlants.isEmpty {
                Section("Due Today") {
                    ForEach(dueTodayPlants) { plant in
                        PlantWaterReminderRow(plant: plant)
                            .swipeActions(edge: .leading) {
                                Button {
                                    waterPlant(plant)
                                } label: {
                                    Label("Watered", systemImage: "drop.fill")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.delete(plant)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    plantToEdit = plant
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
            if !upcomingPlants.isEmpty {
                Section("Upcoming") {
                    ForEach(upcomingPlants) { plant in
                        PlantWaterReminderRow(plant: plant)
                            .swipeActions(edge: .leading) {
                                Button {
                                    waterPlant(plant)
                                } label: {
                                    Label("Watered", systemImage: "drop.fill")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.delete(plant)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    plantToEdit = plant
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var sortedPlants: [PlantWaterReminderPlant] {
        store.plants.sorted {
            nextWateringDate(for: $0) < nextWateringDate(for: $1)
        }
    }

    private var overduePlants: [PlantWaterReminderPlant] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return sortedPlants.filter { nextWateringDate(for: $0) < startOfToday }
    }

    private var dueTodayPlants: [PlantWaterReminderPlant] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!
        return sortedPlants.filter {
            nextWateringDate(for: $0) >= startOfToday &&
            nextWateringDate(for: $0) < endOfToday
        }
    }

    private var upcomingPlants: [PlantWaterReminderPlant] {
        let startOfTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
        return sortedPlants.filter { nextWateringDate(for: $0) >= startOfTomorrow }
    }

    private func nextWateringDate(for plant: PlantWaterReminderPlant) -> Date {
        plant.lastWateredDate.addingTimeInterval(Double(plant.wateringIntervalDays) * 24 * 60 * 60)
    }

    private func waterPlant(_ plant: PlantWaterReminderPlant) {
        var updatedPlant = plant
        updatedPlant.lastWateredDate = Date()
        store.update(updatedPlant)
    }
}

// MARK: - Row View
struct PlantWaterReminderRow: View {
    let plant: PlantWaterReminderPlant

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name)
                    .font(.headline)
                if let species = plant.species, !species.isEmpty {
                    Text(species)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let location = plant.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(nextWateringDate, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(nextWateringDate < Date() ? .red : .primary)
                if plant.wateringIntervalDays > 0 {
                    Text("Every \(plant.wateringIntervalDays) days")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let notes = plant.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var nextWateringDate: Date {
        plant.lastWateredDate.addingTimeInterval(Double(plant.wateringIntervalDays) * 24 * 60 * 60)
    }
}

// MARK: - Edit / Add View
struct PlantWaterReminderEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: PlantWaterReminderStore

    let plant: PlantWaterReminderPlant?

    @State private var name: String
    @State private var species: String
    @State private var wateringIntervalDays: Int
    @State private var notes: String
    @State private var location: String
    @State private var lastWateredDate: Date

    init(plant: PlantWaterReminderPlant?) {
        self.plant = plant
        _name = State(initialValue: plant?.name ?? "")
        _species = State(initialValue: plant?.species ?? "")
        _wateringIntervalDays = State(initialValue: plant?.wateringIntervalDays ?? 7)
        _notes = State(initialValue: plant?.notes ?? "")
        _location = State(initialValue: plant?.location ?? "")
        _lastWateredDate = State(initialValue: plant?.lastWateredDate ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Plant Details") {
                    TextField("Name", text: $name)
                    TextField("Species", text: $species)
                    TextField("Location", text: $location)
                }
                Section("Watering Schedule") {
                    Stepper(value: $wateringIntervalDays, in: 1...365, step: 1) {
                        HStack {
                            Text("Interval")
                            Spacer()
                            Text("\(wateringIntervalDays) days")
                                .foregroundStyle(.secondary)
                        }
                    }
                    DatePicker("Last Watered", selection: $lastWateredDate, displayedComponents: .date)
                }
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(plant == nil ? "Add Plant" : "Edit Plant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existingPlant = plant {
            var updatedPlant = existingPlant
            updatedPlant.name = trimmedName
            updatedPlant.species = species
            updatedPlant.wateringIntervalDays = wateringIntervalDays
            updatedPlant.lastWateredDate = lastWateredDate
            updatedPlant.notes = notes
            updatedPlant.location = location
            store.update(updatedPlant)
        } else {
            let newPlant = PlantWaterReminderPlant(
                id: UUID(),
                name: trimmedName,
                species: species,
                wateringIntervalDays: wateringIntervalDays,
                lastWateredDate: lastWateredDate,
                notes: notes,
                location: location
            )
            store.add(newPlant)
        }
        dismiss()
    }
}