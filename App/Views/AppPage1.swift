import SwiftUI
import Combine

private let AppPage1DateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateFormat = "MMM d, HH:mm"
    return formatter
}()

struct AppPage1View: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @State private var searchText = ""
    @State private var filterIndex = 0
    @State private var selectedLog: AppLogEntry?
    @State private var showingEdit = false
    @State private var showNoTankAlert = false

    var dark: Bool { scheme == .dark }

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            List {
                quickActionsSection
                statsSection
                recentActivitySection
                Section {
                    Color.clear.frame(height: 96)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.bg)
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("Home")
            .AppAppear()
            .alert("No Tank", isPresented: $showNoTankAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please add a tank in the Aquariums tab first.")
            }
            .sheet(isPresented: $showingEdit) {
                if let log = selectedLog {
                    AppPage1EditView(original: log)
                        .environmentObject(store)
                }
            }
        }
    }

    private var quickActionsSection: some View {
        Section {
            HStack(spacing: AppTheme.s3) {
                AppPage1QuickButton(title: "Water Change", systemImage: "drop.fill", tint: .blue, action: "") {
                    quickLog(kind: .waterChange)
                }
                AppPage1QuickButton(title: "Feeding", systemImage: "fork.knife", tint: .orange, action: "") {
                    quickLog(kind: .feeding)
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    private var statsSection: some View {
        Section {
            HStack(spacing: AppTheme.s2) {
                AppPage1StatTile(
                    title: "Water Changes (Month)",
                    value: "\(monthWaterChanges)",
                    unit: "times"
                )
                AppPage1StatTile(
                    title: "Feedings (Month)",
                    value: "\(monthFeedings)",
                    unit: "times"
                )
            }
        }
    }

    private var recentActivitySection: some View {
        Section("Recent Activity") {
            HStack(spacing: AppTheme.s2) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.dim)
                TextField("Search tank or note", text: $searchText)
                    .font(AppTheme.fontBody)
            }
            Picker("Filter", selection: $filterIndex) {
                Text("All").tag(0)
                Text("Water").tag(1)
                Text("Feeding").tag(2)
            }
            .pickerStyle(.segmented)
            if filteredLogs.isEmpty {
                AppPage1EmptyView(message: "No activity yet. Tap a quick action above to log your first water change or feeding.", actionTitle: "Reset Filters", action: "") {
                    searchText = ""
                    filterIndex = 0
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredLogs) { log in
                    AppPage1Row(log: log, tankName: tankName(for: log))
                        .onTapGesture {
                            selectedLog = log
                            showingEdit = true
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteLog(log)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    private var filteredLogs: [AppLogEntry] {
        store.logs.sorted { $0.date > $1.date }.filter { log in
            let kindMatches: Bool = {
                switch filterIndex {
                case 1: return log.kind == .waterChange
                case 2: return log.kind == .feeding
                default: return true
                }
            }()
            let tankName = store.tanks.first { $0.id == log.tankID }?.name ?? ""
            let searchMatches = searchText.isEmpty
                || tankName.localizedCaseInsensitiveContains(searchText)
                || log.note.localizedCaseInsensitiveContains(searchText)
            return kindMatches && searchMatches
        }
    }

    private var monthWaterChanges: Int {
        store.logs.filter { log in
            log.kind == .waterChange
                && Calendar.current.isDate(log.date, equalTo: Date(), toGranularity: .month)
        }.count
    }

    private var monthFeedings: Int {
        store.logs.filter { log in
            log.kind == .feeding
                && Calendar.current.isDate(log.date, equalTo: Date(), toGranularity: .month)
        }.count
    }

    func tankName(for log: AppLogEntry) -> String {
        store.tanks.first { $0.id == log.tankID }?.name ?? "Unknown Tank"
    }

    private func quickLog(kind: AppLogKind) {
        guard let tank = store.tanks.first else {
            showNoTankAlert = true
            return
        }
        let quantity: Double = kind == .waterChange ? 10.0 : 0.0
        let entry = AppLogEntry(
            id: UUID(),
            tankID: tank.id,
            kind: kind,
            quantity: quantity,
            note: "Quick log",
            date: Date()
        )
        withAnimation(AppMotion.press) {
            store.logs.append(entry)
            store.save()
        }
    }

    func deleteLog(_ log: AppLogEntry) {
        withAnimation(AppMotion.press) {
            store.logs.removeAll { $0.id == log.id }
            store.save()
        }
    }
}

struct AppPage1QuickButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.s2) {
                Image(systemName: systemImage)
                    .font(AppTheme.fontTitle)
                    .foregroundColor(tint)
                Text(title)
                    .font(AppTheme.fontBody)
                    .foregroundColor(AppTheme.text)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.s4)
            .background(tint.opacity(0.15))
            .cornerRadius(AppTheme.rCard)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.rCard)
                    .stroke(tint.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(AppPage1PressStyle())
    }
}

struct AppPage1PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(AppMotion.press, value: configuration.isPressed)
    }
}

struct AppPage1StatTile: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.s1) {
            Text(title)
                .font(AppTheme.fontLabel)
                .foregroundColor(AppTheme.dim)
            HStack(alignment: .firstTextBaseline, spacing: AppTheme.s1) {
                Text(value)
                    .font(AppTheme.fontNumber)
                    .foregroundColor(AppTheme.text)
                Text(unit)
                    .font(AppTheme.fontCaption)
                    .foregroundColor(AppTheme.dim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.s3)
        .background(AppTheme.surfaceAlt)
        .cornerRadius(AppTheme.rCard)
    }
}

struct AppPage1Row: View {
    let log: AppLogEntry
    let tankName: String

    var body: some View {
        HStack(spacing: AppTheme.s2) {
            Image(systemName: log.kind == .waterChange ? "drop.fill" : "fork.knife")
                .foregroundColor(log.kind == .waterChange ? .blue : .orange)
            VStack(alignment: .leading, spacing: AppTheme.s1) {
                Text(log.kind == .waterChange ? "Water Change" : "Feeding")
                    .font(AppTheme.fontBody)
                    .foregroundColor(AppTheme.text)
                Text(tankName)
                    .font(AppTheme.fontLabel)
                    .foregroundColor(AppTheme.dim)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: AppTheme.s1) {
                Text(AppPage1DateFormatter.string(from: log.date))
                    .font(AppTheme.fontCaption)
                    .foregroundColor(AppTheme.dim)
                if log.kind == .waterChange {
                    Text("\(log.quantity, specifier: "%.1f") L")
                        .font(AppTheme.fontCaption)
                        .foregroundColor(AppTheme.dim)
                }
            }
        }
        .padding(.vertical, AppTheme.s2)
        .contentShape(Rectangle())
    }
}

struct AppPage1EmptyView: View {
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.s3) {
            AppEmptyArt(size: 120)
            Text(message)
                .font(AppTheme.fontBody)
                .foregroundColor(AppTheme.dim)
                .multilineTextAlignment(.center)
            Button(action: action) {
                Text(actionTitle)
                    .font(AppTheme.fontBody)
                    .foregroundColor(AppTheme.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.s4)
    }
}

struct AppPage1EditView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let original: AppLogEntry

    @State private var kind: AppLogKind
    @State private var quantityText: String
    @State private var note: String
    @State private var date: Date
    @State private var tankID: UUID
    @State private var showDiscardConfirmation = false
    @State private var validationMessage: String?

    init(log: AppLogEntry) {
        original = log
        _kind = State(initialValue: log.kind)
        _quantityText = State(initialValue: String(format: "%.1f", log.quantity))
        _note = State(initialValue: log.note)
        _date = State(initialValue: log.date)
        _tankID = State(initialValue: log.tankID)
    }

    private var isDirty: Bool {
        kind != original.kind
            || date != original.date
            || note != original.note
            || tankID != original.tankID
            || quantityValue != original.quantity
    }

    private var quantityValue: Double {
        Double(quantityText.replacingOccurrences(of: ",", with: ".")) ?? 0.0
    }

    private var isValid: Bool {
        if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        if kind == .waterChange {
            return quantityValue > 0
        }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tank") {
                    Picker("Tank", selection: $tankID) {
                        ForEach(store.tanks) { tank in
                            Text(tank.name).tag(tank.id)
                        }
                    }
                }
                Section("Type") {
                    Picker("Type", selection: $kind) {
                        Text("Water Change").tag(AppLogKind.waterChange)
                        Text("Feeding").tag(AppLogKind.feeding)
                    }
                }
                Section("Date") {
                    DatePicker("Date", selection: $date)
                }
                Section("Details") {
                    TextField("Note", text: $note)
                        .font(AppTheme.fontBody)
                    if kind == .waterChange {
                        TextField("Quantity (L)", text: $quantityText)
                            .keyboardType(.decimalPad)
                            .font(AppTheme.fontBody)
                    }
                }
                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundColor(.red)
                            .font(AppTheme.fontCaption)
                    }
                }
            }
            .navigationTitle("Edit Log")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if isDirty {
                            showDiscardConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
            .confirmationDialog(
                "Discard changes?",
                isPresented: $showDiscardConfirmation
            ) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            }
            .interactiveDismissDisabled(isDirty)
        }
    }

    func save() {
        guard isValid else {
            validationMessage = "Note is required. Quantity must be greater than 0 for water changes."
            return
        }
        let updated = AppLogEntry(
            id: original.id,
            tankID: tankID,
            kind: kind,
            quantity: kind == .waterChange ? quantityValue : 0.0,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date
        )
        if let index = store.logs.firstIndex(where: { $0.id == original.id }) {
            store.logs[index] = updated
            store.save()
        }
        dismiss()
    }
}