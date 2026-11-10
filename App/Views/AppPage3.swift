import SwiftUI
import Combine

private let AppPage3MonthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateFormat = "MMMM yyyy"
    return formatter
}()

private let AppPage3TimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateFormat = "MMM d, HH:mm"
    return formatter
}()

enum AppPage3Filter: String, CaseIterable, Identifiable {
    case all = "All"
    case waterChange = "Water Change"
    case feeding = "Feeding"

    var id: String { rawValue }
}

struct AppPage3View: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @State private var searchText = ""
    @State private var filter: AppPage3Filter = .all
    @State private var visibleMonth = Date()
    @State private var showingAdd = false

    var dark: Bool { scheme == .dark }
    private var contentBackground: Color { dark ? AppTheme.surfaceAlt : AppTheme.surface }

    var monthLogs: [AppLogEntry] {
        let calendar = Calendar.current
        return store.logs.filter { calendar.isDate($0.date, equalTo: visibleMonth, toGranularity: .month) }
    }

    private var displayedLogs: [AppLogEntry] {
        monthLogs
            .filter { entry in
                let tank = tankName(for: entry)
                let matchesSearch = searchText.isEmpty
                    || entry.note.localizedCaseInsensitiveContains(searchText)
                    || tank.localizedCaseInsensitiveContains(searchText)

                let matchesFilter: Bool
                switch filter {
                case .all:
                    matchesFilter = true
                case .waterChange:
                    matchesFilter = isWaterChange(entry)
                case .feeding:
                    matchesFilter = isFeeding(entry)
                }

                return matchesSearch && matchesFilter
            }
            .sorted { $0.date > $1.date }
    }

    var monthTitle: String {
        AppPage3MonthFormatter.string(from: visibleMonth)
    }

    private var waterCount: Int {
        monthLogs.filter { isWaterChange($0) }.count
    }

    var feedingCount: Int {
        monthLogs.filter { isFeeding($0) }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.s4) {
                monthHeader
                searchField
                filterPicker
                summaryTiles

                if displayedLogs.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .padding(.horizontal, AppTheme.s4)
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle("Records")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Record")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AppPage3EditorView(entry: "")
            }
        }
    }

    private var monthHeader: some View {
        HStack(spacing: AppTheme.s4) {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: AppTheme.s6, height: AppTheme.s6)
                    .background(contentBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous Month")

            Spacer()

            VStack(spacing: AppTheme.s2) {
                Text(monthTitle)
                    .font(AppTheme.fontTitle)
                    .foregroundColor(AppTheme.text)
                Text("\(displayedLogs.count) records")
                    .font(AppTheme.fontCaption)
                    .foregroundColor(AppTheme.dim)
            }

            Spacer()

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: AppTheme.s6, height: AppTheme.s6)
                    .background(contentBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next Month")
        }
    }

    private var searchField: some View {
        HStack(spacing: AppTheme.s3) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.dim)

            TextField("Search tank or note", text: $searchText)
                .font(AppTheme.fontBody)
                .foregroundColor(AppTheme.text)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.dim)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppTheme.s4)
        .background(contentBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.rCard)
                .stroke(AppTheme.stroke, lineWidth: 1)
        )
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $filter) {
            ForEach(AppPage3Filter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    private var summaryTiles: some View {
        HStack(spacing: AppTheme.s4) {
            AppStatTile(title: "Total", value: "\(monthLogs.count)", icon: "chart.bar.fill")
            AppStatTile(title: "Water Changes", value: "\(waterCount)", icon: "drop.fill")
            AppStatTile(title: "Feedings", value: "\(feedingCount)", icon: "fish.fill")
        }
    }

    var list: some View {
        List {
            ForEach(displayedLogs) { entry in
                NavigationLink(destination: AppPage3DetailView(entry: entry)) {
                    AppPage3Row(
                        entry: entry,
                        tankName: tankName(for: entry),
                        timeText: AppPage3TimeFormatter.string(from: entry.date)
                    )
                }
                .swipeActions {
                    Button(role: .destructive) {
                        deleteEntry(entry)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .contentMargins(.bottom, 96, for: .scrollContent)
    }

    private var emptyState: some View {
        AppPage3EmptyStateView {
            showingAdd = true
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func moveMonth(by value: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: value, to: visibleMonth) {
            visibleMonth = newDate
        }
    }

    func tankName(for entry: AppLogEntry) -> String {
        store.tanks.first(where: { $0.id == entry.tankID })?.name ?? "Unknown Tank"
    }

    private func isWaterChange(_ entry: AppLogEntry) -> Bool {
        entry.kind.rawValue.lowercased().contains("water")
    }

    private func isFeeding(_ entry: AppLogEntry) -> Bool {
        entry.kind.rawValue.lowercased().contains("feed")
    }

    private func deleteEntry(_ entry: AppLogEntry) {
        withAnimation {
            store.logs.removeAll { $0.id == entry.id }
            persistLogs()
        }
    }

    private func persistLogs() {
        guard let data = try? JSONEncoder().encode(store.logs) else { return }
        try? data.write(to: store.logsURL)
    }
}

struct AppPage3Row: View {
    let entry: AppLogEntry
    let tankName: String
    let timeText: String

    @Environment(\.colorScheme) private var scheme

    var dark: Bool { scheme == .dark }

    var body: some View {
        HStack(spacing: AppTheme.s4) {
            Image(systemName: iconName)
                .font(AppTheme.fontTitle)
                .foregroundColor(iconColor)
                .frame(width: AppTheme.s6, height: AppTheme.s6)
                .padding(AppTheme.s2)
                .background(iconColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppTheme.s2) {
                Text(tankName)
                    .font(AppTheme.fontBody)
                    .foregroundColor(AppTheme.text)
                    .lineLimit(1)

                Text(kindTitle)
                    .font(AppTheme.fontCaption)
                    .foregroundColor(AppTheme.dim)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppTheme.s2) {
                Text(String(format: "%.1f", entry.quantity))
                    .font(AppTheme.fontNumber)
                    .foregroundColor(AppTheme.text)

                Text(timeText)
                    .font(AppTheme.fontCaption)
                    .foregroundColor(AppTheme.dim)
            }
        }
        .padding(.vertical, AppTheme.s3)
        .frame(minHeight: 56)
    }

    private var iconName: String {
        isWaterChange ? "drop.fill" : "fish.fill"
    }

    private var iconColor: Color {
        isWaterChange ? AppTheme.accent : AppTheme.accentSoft
    }

    private var kindTitle: String {
        isWaterChange ? "Water Change" : "Feeding"
    }

    private var isWaterChange: Bool {
        entry.kind.rawValue.lowercased().contains("water")
    }
}

struct AppPage3EmptyStateView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.s4) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(AppTheme.fontTitle)
                .foregroundColor(AppTheme.dim)
                .padding(.bottom, AppTheme.s3)

            Text("No Records")
                .font(AppTheme.fontTitle)
                .foregroundColor(AppTheme.text)

            Text("No entries for this month. Adjust the filter or add your first log.")
                .font(AppTheme.fontBody)
                .foregroundColor(AppTheme.dim)
                .multilineTextAlignment(.center)
                .lineSpacing(AppTheme.s2)

            AppPrimaryButton(title: "Add Record", action: action)
        }
        .padding(AppTheme.s6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AppPage3EditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    let entry: AppLogEntry?

    @State private var selectedTankID: UUID?
    @State private var kindRaw: String
    @State private var quantityText: String
    @State private var noteText: String
    @State private var date: Date
    @State private var useNow: Bool

    init(entry: AppLogEntry? = nil) {
        self.entry = entry
        _selectedTankID = State(initialValue: entry?.tankID)
        _kindRaw = State(initialValue: entry?.kind.rawValue ?? "waterChange")
        _quantityText = State(initialValue: entry.map { String(format: "%.1f", $0.quantity) } ?? "")
        _noteText = State(initialValue: entry?.note ?? "")
        _date = State(initialValue: entry?.date ?? Date())
        _useNow = State(initialValue: entry == nil)
    }

    var dark: Bool { scheme == .dark }
    private var contentBackground: Color { dark ? AppTheme.surfaceAlt : AppTheme.surface }

    private var availableKinds: [String] {
        ["waterChange", "feeding"]
    }

    private var quantityValid: Bool {
        guard let value = Double(quantityText.replacingOccurrences(of: ",", with: ".")) else {
            return false
        }
        return value > 0
    }

    private var noteValid: Bool {
        !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSave: Bool {
        selectedTankID != nil && quantityValid && noteValid
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tank") {
                    Picker("Tank", selection: $selectedTankID) {
                        ForEach(store.tanks) { tank in
                            Text(tank.name).tag(Optional(tank.id))
                        }
                    }
                }

                Section("Type") {
                    Picker("Type", selection: $kindRaw) {
                        ForEach(availableKinds, id: \.self) { kind in
                            Text(kindLabel(for: kind)).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Quantity") {
                    TextField("Quantity", text: $quantityText)
                        .keyboardType(.decimalPad)

                    if !quantityValid && !quantityText.isEmpty {
                        Text("Enter a quantity greater than 0.")
                            .font(AppTheme.fontCaption)
                            .foregroundColor(AppTheme.dim)
                    }
                }

                Section("Note") {
                    TextField("Note", text: $noteText)
                }

                Section("Date") {
                    Toggle("Use current time", isOn: $useNow)

                    if !useNow {
                        DatePicker(
                            "Date",
                            selection: $date,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                Section {
                    AppPrimaryButton(title: "Save Record", action: save)
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.5)
                }
            }
            .navigationTitle(entry == nil ? "Add Record" : "Edit Record")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func kindLabel(for kind: String) -> String {
        kind.lowercased().contains("water") ? "Water Change" : "Feeding"
    }

    func save() {
        guard canSave,
              let tankID = selectedTankID,
              let quantity = Double(quantityText.replacingOccurrences(of: ",", with: ".")),
              let kind = AppLogKind(rawValue: kindRaw) else {
            return
        }

        let log = AppLogEntry(
            id: entry?.id ?? UUID(),
            tankID: tankID,
            kind: kind,
            quantity: quantity,
            note: noteText,
            date: useNow ? Date() : date
        )

        if let index = store.logs.firstIndex(where: { $0.id == log.id }) {
            store.logs[index] = log
        } else {
            store.logs.append(log)
        }

        persistLogs()
        dismiss()
    }

    private func persistLogs() {
        guard let data = try? JSONEncoder().encode(store.logs) else { return }
        try? data.write(to: store.logsURL)
    }
}

struct AppPage3DetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    let entry: AppLogEntry

    @State private var showingEdit = false

    var dark: Bool { scheme == .dark }
    private var contentBackground: Color { dark ? AppTheme.surfaceAlt : AppTheme.surface }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.s4) {
                header
                stats
                detailsCard
                bottomActions
            }
            .padding(AppTheme.s4)
        }
        .background(AppTheme.bg.ignoresSafeArea())
        .navigationTitle("Record Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEdit) {
            AppPage3EditorView(entry: entry)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppTheme.s2) {
            Text(kindTitle)
                .font(AppTheme.fontTitle)
                .foregroundColor(AppTheme.text)

            Text(AppPage3TimeFormatter.string(from: entry.date))
                .font(AppTheme.fontCaption)
                .foregroundColor(AppTheme.dim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stats: some View {
        HStack(spacing: AppTheme.s4) {
            AppStatTile(title: "Quantity", value: String(format: "%.1f", entry.quantity), icon: "number")
            AppStatTile(title: "Tank", value: tankName, icon: "shippingbox.fill")
            AppStatTile(title: "Type", value: kindTitle, icon: iconName)
        }
    }

    private var detailsCard: some View {
        AppCard {
            VStack(spacing: AppTheme.s4) {
                AppPage3DetailRow(label: "Type", value: kindTitle)
                AppPage3DetailRow(label: "Tank", value: tankName)
                AppPage3DetailRow(label: "Quantity", value: String(format: "%.1f", entry.quantity))
                AppPage3DetailRow(label: "Note", value: entry.note.isEmpty ? "—" : entry.note)
                AppPage3DetailRow(label: "Date", value: AppPage3TimeFormatter.string(from: entry.date))
            }
        }
    }

    private var bottomActions: some View {
        VStack(spacing: AppTheme.s3) {
            AppPrimaryButton(title: "Edit Record", action: {
                showingEdit = true
            })

            Button(role: .destructive) {
                deleteAndDismiss()
            } label: {
                Text("Delete Record")
                    .font(AppTheme.fontBody)
                    .foregroundColor(AppTheme.dim)
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.s4)
            }
            .background(contentBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.rCard)
                    .stroke(AppTheme.stroke, lineWidth: 1)
            )
        }
    }

    var tankName: String {
        store.tanks.first(where: { $0.id == entry.tankID })?.name ?? "Unknown Tank"
    }

    private var kindTitle: String {
        entry.kind.rawValue.lowercased().contains("water") ? "Water Change" : "Feeding"
    }

    private var iconName: String {
        entry.kind.rawValue.lowercased().contains("water") ? "drop.fill" : "fish.fill"
    }

    private func deleteAndDismiss() {
        withAnimation {
            store.logs.removeAll { $0.id == entry.id }
            persistLogs()
        }
        dismiss()
    }

    private func persistLogs() {
        guard let data = try? JSONEncoder().encode(store.logs) else { return }
        try? data.write(to: store.logsURL)
    }
}

struct AppPage3DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(AppTheme.fontLabel)
                .foregroundColor(AppTheme.dim)

            Spacer()

            Text(value)
                .font(AppTheme.fontBody)
                .foregroundColor(AppTheme.text)
                .multilineTextAlignment(.trailing)
        }
    }
}