import SwiftUI
import Combine

struct PlantCarePage1View: View {
    @EnvironmentObject var store: PlantCareStore
    @State private var searchText = ""
    @State private var selectedLocationFilter: String? = nil
    @State private var sortAscending = true

    private var locations: [String] {
        Array(Set(store.todayWateringPlants.map { $0.location })).sorted()
    }

    var filteredPlants: [PlantCarePlant] {
        var plants = store.todayWateringPlants
        if let loc = selectedLocationFilter {
            plants = plants.filter { $0.location == loc }
        }
        if !searchText.isEmpty {
            plants = plants.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        plants.sort { sortAscending ? $0.name < $1.name : $0.name > $1.name }
        return plants
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    PlantCarePage1SummaryCard(
                        count: filteredPlants.count,
                        totalAmount: totalWaterAmount(for: filteredPlants)
                    )
                }
                if filteredPlants.isEmpty {
                    PlantCarePage1EmptyState()
                } else {
                    ForEach(filteredPlants) { plant in
                        PlantCarePage1Row(plant: plant, onWater: { markWatered(plant) })
                    }
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by name or location"
            )
            .navigationTitle("Today's Watering")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $sortAscending) {
                            Label("Name A-Z", systemImage: "arrow.up").tag(true)
                            Label("Name Z-A", systemImage: "arrow.down").tag(false)
                        }
                        Picker("Location", selection: $selectedLocationFilter) {
                            Text("All Locations").tag(String?.none)
                            ForEach(locations, id: \.self) { loc in
                                Text(loc).tag(String?.some(loc))
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }

    func markWatered(_ plant: PlantCarePlant) {
        guard let index = store.plants.firstIndex(where: { $0.id == plant.id }) else { return }
        store.plants[index].lastWateredDate = Date()
        let record = PlantCareCareRecord(
            id: UUID(),
            plantID: plant.id,
            type: .water,
            date: Date(),
            amount: 200,
            note: "Watered"
        )
        store.careRecords.append(record)
        store.save()
    }

    private func totalWaterAmount(for plants: [PlantCarePlant]) -> Double {
        Double(plants.count) * 200
    }
}

struct PlantCarePage1SummaryCard: View {
    let count: Int
    let totalAmount: Double

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("\(count)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("plants need water")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(totalAmount, specifier: "%.0f") ml")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("estimated water")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

struct PlantCarePage1Row: View {
    let plant: PlantCarePlant
    let onWater: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name)
                    .font(.headline)
                Text(plant.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    Label("Every \(plant.wateringIntervalDays) days", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let last = plant.lastWateredDate {
                        Text("Last: \(Self.dateFormatter.string(from: last))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Last: Never")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
            Button(action: onWater) {
                Label("Water", systemImage: "drop.fill")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()
}

struct PlantCarePage1EmptyState: View {
    var body: some View {
        ContentUnavailableView {
            Label("All Caught Up", systemImage: "checkmark.circle")
        } description: {
            Text("No plants need watering today.")
        }
    }
}