import SwiftUI
import Foundation

private let page2DateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateFormat = "MMM d, yyyy"
    return formatter
}()

struct AppPage2View: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @State private var searchText = ""
    @State private var showingAdd = false
    @State private var tankToEdit: AppTank?

    var dark: Bool { scheme == .dark }

    private var filteredTanks: [AppTank] {
        let sorted = store.tanks.sorted { $0.createdAt > $1.createdAt }
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.waterType.rawValue.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var totalVolume: Double {
        store.tanks.reduce(0) { $0 + $1.volumeLiters }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.tanks.isEmpty {
                    AppPage2EmptyStateView(searchText: "", hasAnyTanks: false) {
                        showingAdd = true
                    }
                } else {
                    List {
                        Section {
                            summaryHeader
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())

                        if filteredTanks.isEmpty {
                            Section {
                                AppPage2EmptyStateView(searchText: searchText, hasAnyTanks: true) {
                                    searchText = ""
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                        } else {
                            Section {
                                ForEach(filteredTanks) { tank in
                                    AppPage2TankRow(tank: tank)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            tankToEdit = tank
                                        }
                                        .transition(AppMotion.listInsert)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                delete(tank)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                        }
                    }
                    .listStyle(.plain)
                    .background(AppTheme.bg)
                    .scrollContentBackground(.hidden)
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search aquariums")
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle("Aquariums")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(AppMotion.press)
                }
            }
            .sheet(isPresented: $showingAdd) {
                AppPage2AddSheet()
            }
            .sheet(item: $tankToEdit) { tank in
                AppPage2EditSheet(tank: tank)
            }
        }
        .AppAppear()
    }

    private var summaryHeader: some View {
        HStack(spacing: AppLayout.gutter) {
            AppStatTile(value: "\(store.tanks.count)", label: "Tanks", icon: "water.waves")
            AppStatTile(value: String(format: "%.1f L", totalVolume), label: "Total Volume", icon: "drop.fill")
            AppStatTile(value: "\(store.logs.count)", label: "Logs", icon: "list.bullet.clipboard")
        }
        .padding(.vertical, AppLayout.stack)
    }

    private func delete(_ tank: AppTank) {
        var updated = store.tanks
        updated.removeAll { $0.id == tank.id }
        store.tanks = updated
        store.save()
    }
}

private struct AppPage2EmptyStateView: View {
    let searchText: String
    let hasAnyTanks: Bool
    let onAction: () -> Void

    var body: some View {
        VStack(spacing: AppLayout.stack) {
            AppEmptyArt(size: 120)
            Text(hasAnyTanks ? "No Matching Aquariums" : "No Aquariums Yet")
                .font(AppType.font(.headline))
                .foregroundColor(AppTheme.text)
                .multilineTextAlignment(.center)
            Text(hasAnyTanks ? "Try a different name or clear the search." : "Add your first aquarium to start logging water changes and feedings.")
                .font(AppType.font(.body))
                .foregroundColor(AppTheme.dim)
                .multilineTextAlignment(.center)
                .lineSpacing(AppType.lineSpacing(.body))
            AppPrimaryButton(title: hasAnyTanks ? "Clear Search" : "Add Aquarium", systemImage: hasAnyTanks ? "xmark.circle" : "plus.circle.fill") {
                onAction()
            }
            .buttonStyle(AppMotion.press)
        }
        .padding(AppLayout.page)
        .frame(maxWidth: .infinity)
    }
}

private struct AppPage2TankRow: View {
    let tank: AppTank

    var body: some View {
        AppCard {
            HStack(spacing: AppLayout.gutter) {
                Image(systemName: "water.waves")
                    .font(AppType.font(.title2))
                    .foregroundColor(AppTheme.accent)
                    .frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: AppLayout.xs) {
                    Text(tank.name)
                        .font(AppType.font(.headline))
                        .foregroundColor(AppTheme.text)
                    Text("\(String(format: "%.1f", tank.volumeLiters)) L · \(tank.waterType.rawValue)")
                        .font(AppType.font(.footnote))
                        .foregroundColor(AppTheme.dim)
                    Text("Added \(page2DateFormatter.string(from: tank.createdAt))")
                        .font(AppType.font(.caption))
                        .foregroundColor(AppTheme.dim)
                    if !tank.notes.isEmpty {
                        Text(tank.notes)
                            .font(AppType.font(.caption))
                            .foregroundColor(AppTheme.dim)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(AppType.font(.footnote))
                    .foregroundColor(AppTheme.dim)
            }
            .padding(AppLayout.stack)
            .frame(minHeight: AppLayout.minTap)
        }
    }
}

private struct AppPage2AddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    @State private var name = ""
    @State private var volume = 100.0
    @State private var notes = ""
    @State private var waterTypeIndex = 0

    private var waterTypes: [AppWaterType] { AppWaterType.allCases }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && volume > 0
    }

    private var selectedWaterType: AppWaterType {
        guard !waterTypes.isEmpty else { return AppWaterType(rawValue: "Freshwater")! }
        return waterTypes[min(waterTypeIndex, waterTypes.count - 1)]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Aquarium Details") {
                    VStack(alignment: .leading, spacing: AppLayout.xs) {
                        Text("Name").font(AppType.font(.label)).foregroundColor(AppTheme.dim)
                        TextField("e.g. Living Room 55L", text: $name)
                            .font(AppType.font(.body))
                    }
                    .padding(.vertical, AppLayout.sm)

                    VStack(alignment: .leading, spacing: AppLayout.xs) {
                        Text("Volume (liters)").font(AppType.font(.label)).foregroundColor(AppTheme.dim)
                        TextField("Volume (liters)", value: $volume, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .font(AppType.font(.body))
                    }
                    .padding(.vertical, AppLayout.sm)

                    Picker("Water Type", selection: $waterTypeIndex) {
                        ForEach(0..<waterTypes.count, id: \.self) { index in
                            Text(waterTypes[index].rawValue)
                        }
                    }
                    .font(AppType.font(.body))

                    VStack(alignment: .leading, spacing: AppLayout.xs) {
                        Text("Notes").font(AppType.font(.label)).foregroundColor(AppTheme.dim)
                        TextField("Optional notes", text: $notes)
                            .font(AppType.font(.body))
                    }
                    .padding(.vertical, AppLayout.sm)
                }

                Section {
                    AppPrimaryButton(title: "Add Aquarium", systemImage: "plus.circle.fill") {
                        save()
                    }
                    .disabled(!canSave)
                    .buttonStyle(AppMotion.press)
                }
            }
            .navigationTitle("New Aquarium")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(AppMotion.press)
                }
            }
        }
    }

    func save() {
        let newTank = AppTank(id: UUID(), name: name.trimmingCharacters(in: .whitespacesAndNewlines), volumeLiters: volume, waterType: selectedWaterType, createdAt: Date(), notes: notes.trimmingCharacters(in: .whitespacesAndNewlines), localizedCaseInsensitiveContains: "")
        var updated = store.tanks
        updated.append(newTank)
        store.tanks = updated
        store.save()
        dismiss()
    }
}

private struct AppPage2EditSheet: View {
    let tank: AppTank
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    @State private var name: String
    @State private var volume: Double
    @State private var notes: String
    @State private var waterTypeIndex: Int

    init(tank: AppTank) {
        self.tank = tank
        _name = State(initialValue: tank.name)
        _volume = State(initialValue: tank.volumeLiters)
        _notes = State(initialValue: tank.notes)
        let cases = AppWaterType.allCases
        _waterTypeIndex = State(initialValue: cases.firstIndex { $0.rawValue == tank.waterType.rawValue } ?? 0)
    }

    private var waterTypes: [AppWaterType] { AppWaterType.allCases }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && volume > 0
    }

    private var selectedWaterType: AppWaterType {
        guard !waterTypes.isEmpty else { return AppWaterType(rawValue: "Freshwater")! }
        return waterTypes[min(waterTypeIndex, waterTypes.count - 1)]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Aquarium Details") {
                    VStack(alignment: .leading, spacing: AppLayout.xs) {
                        Text("Name").font(AppType.font(.label)).foregroundColor(AppTheme.dim)
                        TextField("Aquarium name", text: $name)
                            .font(AppType.font(.body))
                    }
                    .padding(.vertical, AppLayout.sm)

                    VStack(alignment: .leading, spacing: AppLayout.xs) {
                        Text("Volume (liters)").font(AppType.font(.label)).foregroundColor(AppTheme.dim)
                        TextField("Volume (liters)", value: $volume, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .font(AppType.font(.body))
                    }
                    .padding(.vertical, AppLayout.sm)

                    Picker("Water Type", selection: $waterTypeIndex) {
                        ForEach(0..<waterTypes.count, id: \.self) { index in
                            Text(waterTypes[index].rawValue)
                        }
                    }
                    .font(AppType.font(.body))

                    VStack(alignment: .leading, spacing: AppLayout.xs) {
                        Text("Notes").font(AppType.font(.label)).foregroundColor(AppTheme.dim)
                        TextField("Optional notes", text: $notes)
                            .font(AppType.font(.body))
                    }
                    .padding(.vertical, AppLayout.sm)
                }

                Section {
                    AppPrimaryButton(title: "Save Changes", systemImage: "checkmark.circle.fill") {
                        save()
                    }
                    .disabled(!canSave)
                    .buttonStyle(AppMotion.press)
                }
            }
            .navigationTitle("Edit Aquarium")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(AppMotion.press)
                }
            }
        }
    }

    func save() {
        guard let idx = store.tanks.firstIndex(where: { $0.id == tank.id }) else { return }
        var updated = store.tanks
        updated[idx].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated[idx].volumeLiters = volume
        updated[idx].waterType = selectedWaterType
        updated[idx].notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        store.tanks = updated
        store.save()
        dismiss()
    }
}