import SwiftUI
import Foundation

// MARK: - Date Formatter
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

// MARK: - Root Tab View
struct AppTabView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.doc.horizontal")
                }

            RecordListView()
                .tabItem {
                    Label("Records", systemImage: "list.bullet")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var store: AppStore

    private var latestRecord: AppGrowthRecord? {
        store.records.max(by: { $0.date < $1.date })
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if let record = latestRecord {
                        metrics(for: record)
                    } else {
                        Text("No records yet. Add your first measurement.")
                            .foregroundColor(.secondary)
                    }
                    GrowthChartView(records: store.records)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddRecordView()) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(store.childName)
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Born \(store.birthDate, formatter: dateFormatter)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func metrics(for record: AppGrowthRecord) -> some View {
        let age = ageString(for: record.date)
        return HStack(spacing: 12) {
            MetricCard(title: "Height", value: "\(record.height, specifier: "%.1f") cm", systemImage: "arrow.up.and.down")
            MetricCard(title: "Weight", value: "\(record.weight, specifier: "%.2f") kg", systemImage: "scalemass")
            MetricCard(title: "Age", value: age, systemImage: "calendar")
        }
    }

    private func ageString(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: store.birthDate, to: date)
        if let years = components.year, years > 0 {
            return "\(years)y \(components.month ?? 0)m"
        } else if let months = components.month, months > 0 {
            return "\(months)m"
        } else {
            return "\(components.day ?? 0)d"
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Growth Chart (simplified list)
struct GrowthChartView: View {
    let records: [AppGrowthRecord]

    var sortedRecords: [AppGrowthRecord] {
        records.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Measurements")
                .font(.headline)
            if sortedRecords.isEmpty {
                Text("No measurements.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(sortedRecords.suffix(10), id: \.id) { record in
                    HStack {
                        Text(record.date, formatter: dateFormatter)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(record.height, specifier: "%.1f") cm")
                            .font(.caption)
                        Text("\(record.weight, specifier: "%.2f") kg")
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Record List View
struct RecordListView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingAddRecord = false

    private var sortedRecords: [AppGrowthRecord] {
        store.records.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(sortedRecords, id: \.id) { record in
                    RecordRowView(record: record)
                }
                .onDelete(perform: deleteRecords)
            }
            .navigationTitle("Records")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddRecord = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRecord) {
                AddRecordView()
            }
        }
    }

    func deleteRecords(at offsets: IndexSet) {
        let recordsToDelete = offsets.map { sortedRecords[$0] }
        store.records.removeAll { record in
            recordsToDelete.contains { $0.id == record.id }
        }
    }
}

// MARK: - Record Row
struct RecordRowView: View {
    let record: AppGrowthRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.date, formatter: dateFormatter)
                    .font(.headline)
                if let note = record.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(record.height, specifier: "%.1f") cm")
                    .font(.subheadline)
                Text("\(record.weight, specifier: "%.2f") kg")
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Record View
struct AddRecordView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var heightText = ""
    @State private var weightText = ""
    @State private var note = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Measurement") {
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                    TextField("Height (cm)", text: $heightText)
                        .keyboardType(.decimalPad)
                    TextField("Weight (kg)", text: $weightText)
                        .keyboardType(.decimalPad)
                }
                Section("Note") {
                    TextField("Optional note", text: $note)
                }
            }
            .navigationTitle("Add Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecord()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        guard let height = Double(heightText), let weight = Double(weightText) else {
            return false
        }
        return height > 0 && weight > 0
    }

    private func saveRecord() {
        guard let height = Double(heightText),
              let weight = Double(weightText),
              height > 0, weight > 0 else {
            return
        }
        let record = AppGrowthRecord(
            id: UUID(),
            date: date,
            height: height,
            weight: weight,
            note: note.isEmpty ? nil : note
        )
        store.records.append(record)
        dismiss()
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @State private var childName = ""
    @State private var birthDate = Date()

    var body: some View {
        NavigationView {
            Form {
                Section("Child Information") {
                    TextField("Child Name", text: $childName)
                    DatePicker("Birth Date", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                }
            }
            .navigationTitle("Profile")
            .onAppear(perform: loadData)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveData()
                    }
                }
            }
        }
    }

    private func loadData() {
        childName = store.childName
        birthDate = store.birthDate
    }

    private func saveData() {
        store.childName = childName
        store.birthDate = birthDate
    }
}