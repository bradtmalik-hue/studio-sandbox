import SwiftUI

struct AppRecordEntryView: View {
    enum RecordType: String, CaseIterable, Identifiable {
        case fuel = "Fuel"
        case maintenance = "Maintenance"
        var id: String { rawValue }
    }

    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var recordType: RecordType = .fuel
    @State private var date = Date()
    @State private var odometer = ""
    @State private var cost = ""
    @State private var liters = ""
    @State private var pricePerLiter = ""
    @State private var mileage = ""
    @State private var amount = ""
    @State private var itemName = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Type", selection: $recordType) {
                        ForEach(RecordType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                if recordType == .fuel {
                    Section(header: Text("Fuel")) {
                        TextField("Odometer", text: $odometer)
                            .keyboardType(.decimalPad)
                        TextField("Cost", text: $cost)
                            .keyboardType(.decimalPad)
                        TextField("Liters", text: $liters)
                            .keyboardType(.decimalPad)
                        TextField("Price per liter", text: $pricePerLiter)
                            .keyboardType(.decimalPad)
                    }
                } else {
                    Section(header: Text("Maintenance")) {
                        TextField("Mileage", text: $mileage)
                            .keyboardType(.decimalPad)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                        TextField("Item name", text: $itemName)
                    }
                }

                Button("Save") {
                    save()
                }
                .disabled(!isValid)
            }
            .navigationTitle("New Record")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var isValid: Bool {
        switch recordType {
        case .fuel:
            return [odometer, cost, liters, pricePerLiter].allSatisfy { Double($0) != nil }
        case .maintenance:
            return Double(mileage) != nil && Double(amount) != nil && !itemName.isEmpty
        }
    }

    private func save() {
        switch recordType {
        case .fuel:
            let record = AppFuelRecord(
                id: UUID(),
                date: date,
                odometer: Double(odometer) ?? 0,
                cost: Double(cost) ?? 0,
                liters: Double(liters) ?? 0
            )
            store.fuelRecords.append(record)
        case .maintenance:
            let record = AppMaintenanceRecord(
                id: UUID(),
                date: date,
                mileage: Double(mileage) ?? 0,
                amount: Double(amount) ?? 0,
                itemName: itemName
            )
            store.maintenanceRecords.append(record)
        }
        dismiss()
    }
}