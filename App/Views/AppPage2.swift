import SwiftUI

private enum AppPage2Format {
    static func date(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    static func km(_ value: Double) -> String {
        return String(format: "%.0f", value)
    }

    static func cost(_ value: Double) -> String {
        return String(format: "%.2f", value)
    }
}

struct AppPage2View: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var searchText = ""
    @State private var filterType: AppMaintenanceType? = nil
    @State private var showingAdd = false

    var sortedRecords: [AppMaintenanceRecord] {
        store.records.sorted { $0.date > $1.date }
    }

    private var availableTypes: [AppMaintenanceType] {
        var result: [AppMaintenanceType] = []
        for record in store.records {
            if !result.contains(record.type) {
                result.append(record.type)
            }
        }
        return result
    }

    private var filteredRecords: [AppMaintenanceRecord] {
        let sorted = sortedRecords
        guard !searchText.isEmpty || filterType != nil else { return sorted }
        return sorted.filter { record in
            let matchesSearch = searchText.isEmpty ||
                record.component.localizedCaseInsensitiveContains(searchText) ||
                record.notes.localizedCaseInsensitiveContains(searchText)
            let matchesType: Bool
            if let type = filterType {
                matchesType = record.type == type
            } else {
                matchesType = true
            }
            return matchesSearch && matchesType
        }
    }

    var body: some View {
        AppScreen {
            NavigationStack {
                List {
                    Section {
                        summaryCard
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    Section {
                        filterPicker
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    if filteredRecords.isEmpty {
                        Section {
                            AppPage2EmptyView {
                                showingAdd = true
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        Section {
                            ForEach(filteredRecords) { record in
                                NavigationLink {
                                    AppPage2DetailView(record: record)
                                } label: {
                                    AppPage2RecordRow(
                                        record: record,
                                        dateText: AppPage2Format.date(record.date),
                                        intervalText: intervalText(for: record)
                                    )
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        delete(record)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .contentMargins(.bottom, 96, for: .scrollContent)
                .navigationTitle("Maintenance Records")
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search component or notes"
                )
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingAdd = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAdd) {
                    AppPage2EditView(existingRecord: nil, result: "")
                        .environmentObject(store)
                }
            }
        }
    }

    private var summaryCard: some View {
        AppCard {
            HStack(spacing: AppTheme.s2) {
                AppStatTile(
                    label: "Total Records",
                    value: "\(store.totalRecords)",
                    unit: "times",
                    icon: "wrench.and.screwdriver.fill"
                )
                Divider()
                AppStatTile(
                    label: "Current Odometer",
                    value: AppPage2Format.km(store.currentOdometer),
                    unit: "km",
                    icon: "gauge.with.dots.needle.50percent"
                )
            }
        }
    }

    private var filterPicker: some View {
        Picker("Type", selection: $filterType) {
            Text("All Types").tag(AppMaintenanceType?.none)
            ForEach(0..<availableTypes.count, id: \.self) { index in
                Text(availableTypes[index].rawValue).tag(Optional(availableTypes[index]))
            }
        }
        .pickerStyle(.menu)
    }

    private func intervalText(for record: AppMaintenanceRecord) -> String {
        let ordered = sortedRecords
        guard let idx = ordered.firstIndex(where: { $0.id == record.id }) else {
            return "First record"
        }
        let next = idx + 1
        guard next < ordered.count else {
            return "First record"
        }
        let previous = ordered[next]
        let km = record.odometerKm - previous.odometerKm
        let days = Calendar.current.dateComponents([.day], from: previous.date, to: record.date).day ?? 0
        if km > 0 {
            return String(format: "%.0f km · %d days", km, days)
        } else {
            return "\(days) days"
        }
    }

    private func delete(_ record: AppMaintenanceRecord) {
        store.records.removeAll { $0.id == record.id }
        store.save()
    }
}

struct AppPage2RecordRow: View {
    let record: AppMaintenanceRecord
    let dateText: String
    let intervalText: String

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.s2) {
                HStack {
                    AppBadge(text: record.type.rawValue, color: AppTheme.accentSoft)
                    Spacer()
                    Text("\(AppPage2Format.km(record.odometerKm)) km")
                        .font(AppTheme.fontNumber)
                        .foregroundStyle(AppTheme.accent)
                }
                Text(record.component)
                    .font(AppTheme.fontBody)
                    .foregroundStyle(AppTheme.text)
                HStack {
                    Text(dateText)
                    Spacer()
                    Text(intervalText)
                }
                .font(AppTheme.fontCaption)
                .foregroundStyle(AppTheme.dim)
            }
            .padding(AppTheme.s3)
        }
    }
}

struct AppPage2EmptyView: View {
    let onAdd: () -> Void

    var body: some View {
        AppEmptyState(
            icon: "tray",
            title: "No Maintenance Records",
            message: "Add your first chain service to start tracking intervals.",
            buttonTitle: "Add Record"
        ) {
            onAdd()
        }
    }
}

struct AppPage2DetailView: View {
    let record: AppMaintenanceRecord
    @EnvironmentObject private var store: AppDataStore
    @State private var showingEdit = false

    var body: some View {
        AppScreen {
            List {
                Section("Record Details") {
                    AppCard {
                        VStack(alignment: .leading, spacing: AppTheme.s2) {
                            detailRow(label: "Component", value: record.component, icon: "gearshape")
                            detailRow(label: "Type", value: record.type.rawValue, icon: "tag")
                            detailRow(label: "Date", value: AppPage2Format.date(record.date), icon: "calendar")
                            detailRow(label: "Odometer", value: "\(AppPage2Format.km(record.odometerKm)) km", icon: "gauge")
                            detailRow(label: "Cost", value: AppPage2Format.cost(record.cost), icon: "dollarsign.circle")
                            detailRow(label: "Duration", value: "\(record.durationMinutes) min", icon: "clock")
                            detailRow(label: "Notes", value: record.notes.isEmpty ? "—" : record.notes, icon: "note.text")
                        }
                    }
                }
            }
            .navigationTitle("Record Details")
            .toolbar {
                Button("Edit") {
                    showingEdit = true
                }
            }
            .sheet(isPresented: $showingEdit) {
                AppPage2EditView(existingRecord: record, result: "")
                    .environmentObject(store)
            }
        }
    }

    private func detailRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(AppTheme.fontLabel)
                .foregroundStyle(AppTheme.dim)
            Spacer()
            Text(value)
                .font(AppTheme.fontBody)
                .foregroundStyle(AppTheme.text)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct AppPage2EditView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let existingRecord: AppMaintenanceRecord?

    @State private var component: String
    @State private var notes: String
    @State private var date: Date
    @State private var type: AppMaintenanceType?
    @State private var odometerText: String
    @State private var costText: String
    @State private var durationText: String

    init(record: AppMaintenanceRecord?) {
        self.existingRecord = record
        _component = State(initialValue: record?.component ?? "")
        _notes = State(initialValue: record?.notes ?? "")
        _date = State(initialValue: record?.date ?? Date())
        _type = State(initialValue: record?.type ?? nil)
        _odometerText = State(initialValue: record.map { String(format: "%.0f", $0.odometerKm) } ?? "")
        _costText = State(initialValue: record.map { String(format: "%.2f", $0.cost) } ?? "")
        _durationText = State(initialValue: record.map { String(format: "%d", $0.durationMinutes) } ?? "")
    }

    private var availableTypes: [AppMaintenanceType] {
        var result: [AppMaintenanceType] = []
        for record in store.records {
            if !result.contains(record.type) {
                result.append(record.type)
            }
        }
        return result
    }

    private var canSave: Bool {
        guard !component.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              type != nil,
              let odometer = Double(odometerText), odometer >= 0,
              let cost = Double(costText), cost >= 0,
              let duration = Int(durationText), duration > 0 else {
            return false
        }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Component") {
                    TextField("e.g. Shimano 105 Chain", text: $component)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Schedule") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Picker("Type", selection: $type) {
                        Text("Select Type").tag(AppMaintenanceType?.none)
                        ForEach(0..<availableTypes.count, id: \.self) { index in
                            Text(availableTypes[index].rawValue).tag(Optional(availableTypes[index]))
                        }
                    }
                }

                Section("Meters") {
                    TextField("Odometer (km)", text: $odometerText)
                        .keyboardType(.decimalPad)
                    TextField("Cost", text: $costText)
                        .keyboardType(.decimalPad)
                    TextField("Duration (minutes)", text: $durationText)
                        .keyboardType(.numberPad)
                }

                Section {
                    AppPrimaryButton(title: existingRecord == nil ? "Add Record" : "Save Changes") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .navigationTitle(existingRecord == nil ? "Add Record" : "Edit Record")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    func save() {
        guard let selectedType = type else { return }
        let odometer = Double(odometerText) ?? 0
        let cost = Double(costText) ?? 0
        let duration = Int(durationText) ?? 0
        let newRecord = AppMaintenanceRecord(
            id: existingRecord?.id ?? UUID(),
            date: date,
            type: selectedType,
            component: component,
            notes: notes,
            odometerKm: odometer,
            cost: cost,
            durationMinutes: duration
        )

        if let existing = existingRecord {
            if let idx = store.records.firstIndex(where: { $0.id == existing.id }) {
                store.records[idx] = newRecord
            }
        } else {
            store.records.append(newRecord)
        }
        store.save()
        dismiss()
    }
}