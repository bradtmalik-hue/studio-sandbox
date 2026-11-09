import SwiftUI

enum PlantCarePage2Filter: String, CaseIterable, Identifiable {
    case all = "All"
    case dueToday = "Due Today"
    case overdue = "Overdue"

    var id: String { rawValue }
}

enum PlantCarePage2Sort: String, CaseIterable, Identifiable {
    case name = "Name"
    case location = "Location"
    case interval = "Watering Interval"

    var id: String { rawValue }
}

struct PlantCarePage2View: View {
    @EnvironmentObject var store: PlantCareStore
    @State private var searchText = ""
    @State private var filter: PlantCarePage2Filter = .all
    @State private var sort: PlantCarePage2Sort = .name
    @State private var showAddPlant = false

    var filteredPlants: [PlantCarePlant] {
        var plants = store.plants

        if !searchText.isEmpty {
            plants = plants.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch filter {
        case .all:
            break
        case .dueToday:
            let today = Calendar.current.startOfDay(for: Date())
            plants = plants.filter { plant in
                guard let last = plant.lastWateredDate else { return true }
                let next = Calendar.current.date(byAdding: .day, value: plant.wateringIntervalDays, to: last) ?? last
                return Calendar.current.isDate(next, inSameDayAs: today)
            }
        case .overdue:
            let now = Date()
            plants = plants.filter { plant in
                guard let last = plant.lastWateredDate else { return true }
                let next = Calendar.current.date(byAdding: .day, value: plant.wateringIntervalDays, to: last) ?? last
                return next < now
            }
        }

        switch sort {
        case .name:
            plants.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .location:
            plants.sort { $0.location.localizedCaseInsensitiveCompare($1.location) == .orderedAscending }
        case .interval:
            plants.sort { $0.wateringIntervalDays < $1.wateringIntervalDays }
        }

        return plants
    }

    private var averageWateringInterval: Double {
        guard !store.plants.isEmpty else { return 0 }
        let total = store.plants.reduce(0) { $0 + $1.wateringIntervalDays }
        return Double(total) / Double(store.plants.count)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    PlantCarePage2SummaryCard(
                        totalPlants: store.plants.count,
                        dueToday: store.todayWateringPlants.count,
                        averageIntervalDays: averageWateringInterval
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section {
                    PlantCarePage2SearchFilterBar(
                        searchText: $searchText,
                        filter: $filter,
                        sort: $sort
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                if filteredPlants.isEmpty {
                    Section {
                        PlantCarePage2EmptyView {
                            showAddPlant = true
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } else {
                    Section("Plants") {
                        ForEach(filteredPlants) { plant in
                            PlantCarePage2Row(
                                plant: plant,
                                onMarkWatered: {
                                    markWatered(plant)
                                }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(plant)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("All Plants")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddPlant = true
                    } label: {
                        Label("Add Plant", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddPlant) {
                PlantCarePage2AddPlantSheet()
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }

    func markWatered(_ plant: PlantCarePlant) {
        guard let index = store.plants.firstIndex(where: { $0.id == plant.id }) else { return }
        store.plants[index].lastWateredDate = Date()
        store.save()
    }

    func delete(_ plant: PlantCarePlant) {
        guard let index = store.plants.firstIndex(where: { $0.id == plant.id }) else { return }
        store.plants.remove(at: index)
        store.save()
    }
}

struct PlantCarePage2SummaryCard: View {
    let totalPlants: Int
    let dueToday: Int
    let averageIntervalDays: Double

    var body: some View {
        HStack(spacing: 16) {
            PlantCarePage2SummaryItem(
                icon: "leaf.fill",
                value: "\(totalPlants)",
                label: "Total Plants"
            )

            Divider()

            PlantCarePage2SummaryItem(
                icon: "drop.fill",
                value: "\(dueToday)",
                label: "Due Today"
            )

            Divider()

            PlantCarePage2SummaryItem(
                icon: "calendar",
                value: String(format: "%.1f", averageIntervalDays),
                label: "Avg Days"
            )
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PlantCarePage2SummaryItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)

            Text(value)
                .font(.title2.bold())

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PlantCarePage2SearchFilterBar: View {
    @Binding var searchText: String
    @Binding var filter: PlantCarePage2Filter
    @Binding var sort: PlantCarePage2Sort

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search name or location", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
            }
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Picker("Filter", selection: $filter) {
                ForEach(PlantCarePage2Filter.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text("Sort by")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Picker("Sort by", selection: $sort) {
                    ForEach(PlantCarePage2Sort.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PlantCarePage2EmptyView: View {
    let onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Plants Yet", systemImage: "leaf")
        } description: {
            Text("Add your first plant to start tracking watering schedules.")
        } actions: {
            Button("Add Plant", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
    }
}

struct PlantCarePage2Row: View {
    let plant: PlantCarePlant
    let onMarkWatered: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name)
                    .font(.headline)

                Text(plant.location)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("Every \(plant.wateringIntervalDays) days")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(lastWateredText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(action: onMarkWatered) {
                    Label("Watered", systemImage: "drop.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
        }
        .padding(.vertical, 4)
    }

    private var lastWateredText: String {
        guard let date = plant.lastWateredDate else {
            return "Never watered"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d, h:mm a"
        return "Last: \(formatter.string(from: date))"
    }
}

struct PlantCarePage2AddPlantSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: PlantCareStore

    @State private var name = ""
    @State private var location = ""
    @State private var wateringIntervalDays = 7
    @State private var notes = ""
    @State private var showValidationError = false

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (1...365).contains(wateringIntervalDays)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Plant Details") {
                    TextField("Name", text: $name)
                    TextField("Location", text: $location)

                    Stepper(
                        "Water every \(wateringIntervalDays) days",
                        value: $wateringIntervalDays,
                        in: 1...365
                    )

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button("Save Plant") {
                        savePlant()
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Add Plant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Invalid Plant", isPresented: $showValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a name and location, and keep watering interval between 1 and 365 days.")
            }
        }
    }

    func savePlant() {
        guard isFormValid else {
            showValidationError = true
            return
        }

        let newPlant = PlantCarePlant(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            wateringIntervalDays: wateringIntervalDays,
            lastWateredDate: nil,
            lastFertilizedDate: nil,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        store.plants.append(newPlant)
        store.save()
        dismiss()
    }
}