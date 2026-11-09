import SwiftUI

fileprivate enum BeanStockPage3Format {
    static let recordDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter
    }()
    
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    static func recordDate(_ date: Date) -> String {
        recordDateFormatter.string(from: date)
    }
    
    static func shortDate(_ date: Date) -> String {
        shortDateFormatter.string(from: date)
    }
}

struct BeanStockPage3View: View {
    @EnvironmentObject private var store: BeanStockStore
    
    @State private var selectedBagID: UUID = UUID()
    @State private var recordType: BeanStockRecordType = BeanStockRecordType.allCases.first!
    @State private var amountGrams: Double = 18.0
    @State private var date: Date = Date()
    @State private var note: String = ""
    @State private var method: String = "Pour Over"
    @State private var grindSize: String = "Medium"
    @State private var waterAmountMl: Double = 270.0
    @State private var rating: Int = 3
    @State private var showOnlyBrew: Bool = false
    @State private var showAddBag: Bool = false
    @State private var showValidationAlert: Bool = false
    @State private var showSaveConfirmation: Bool = false
    @State private var validationMessage: String = ""
    
    private let methods = ["Pour Over", "French Press", "Espresso", "AeroPress", "Cold Brew"]
    private let grindSizes = ["Extra Fine", "Fine", "Medium", "Coarse", "Extra Coarse"]
    
    private var selectedBag: BeanStockCoffeeBag? {
        store.bags.first(where: { $0.id == selectedBagID })
    }
    
    private var isBrewType: Bool {
        let raw = recordType.rawValue.lowercased()
        return raw.contains("brew") || raw.contains("consume")
    }
    
    var isFormValid: Bool {
        selectedBag != nil && amountGrams > 0
    }
    
    private var todayBrewGrams: Double {
        store.records
            .filter { $0.type.rawValue.lowercased().contains("brew") && Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amountGrams }
    }
    
    var filteredRecords: [BeanStockRecord] {
        let sorted = store.records.sorted { $0.date > $1.date }
        if showOnlyBrew {
            return sorted.filter { $0.type.rawValue.lowercased().contains("brew") }
        }
        return sorted
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    BeanStockPage3SummaryCard(
                        totalBags: store.totalBags,
                        totalStock: store.totalStockGrams,
                        todayBrewGrams: todayBrewGrams,
                        recentDate: store.mostRecentRecordDate
                    )
                } header: {
                    Text("Inventory Snapshot")
                }
                
                if store.bags.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("No Coffee Bags", systemImage: "bag")
                        } description: {
                            Text("Add a coffee bag before logging your first entry.")
                        } actions: {
                            Button("Add Coffee Bag") {
                                showAddBag = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    Section {
                        Picker("Coffee Bag", selection: $selectedBagID) {
                            ForEach(store.bags) { bag in
                                Text("\(bag.name) · \(String(format: "%.0f g", bag.stockWeightGrams))")
                                    .tag(bag.id)
                            }
                        }
                        
                        Picker("Entry Type", selection: $recordType) {
                            ForEach(BeanStockRecordType.allCases) { type in
                                Text(recordTypeName(type)).tag(type)
                            }
                        }
                        
                        DatePicker("Date", selection: $date)
                        
                        HStack {
                            Text("Amount (g)")
                            Spacer()
                            TextField("0", value: $amountGrams, format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                            Stepper("", value: $amountGrams, in: 0...2000, step: 0.5)
                                .labelsHidden()
                        }
                        
                        Picker("Method", selection: $method) {
                            ForEach(methods, id: \.self) { text in
                                Text(text).tag(text)
                            }
                        }
                        
                        Picker("Grind Size", selection: $grindSize) {
                            ForEach(grindSizes, id: \.self) { text in
                                Text(text).tag(text)
                            }
                        }
                        
                        HStack {
                            Text("Water (ml)")
                            Spacer()
                            TextField("0", value: $waterAmountMl, format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                            Stepper("", value: $waterAmountMl, in: 0...2000, step: 5)
                                .labelsHidden()
                        }
                        
                        Stepper(value: $rating, in: 1...5) {
                            HStack {
                                Text("Rating")
                                Spacer()
                                HStack(spacing: 2) {
                                    ForEach(1...5, id: \.self) { index in
                                        Image(systemName: index <= rating ? "star.fill" : "star")
                                            .font(.caption)
                                            .foregroundStyle(index <= rating ? Color.yellow : Color.gray)
                                    }
                                }
                            }
                        }
                        
                        TextField("Note", text: $note)
                        
                        Button {
                            saveEntry()
                        } label: {
                            Label("Save Entry", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(!isFormValid)
                    } header: {
                        Text("New Entry")
                    }
                }
                
                Section {
                    Toggle(isOn: $showOnlyBrew) {
                        Label("Show brew entries only", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    
                    if filteredRecords.isEmpty {
                        ContentUnavailableView {
                            Label("No Entries Yet", systemImage: "list.bullet.clipboard")
                        } description: {
                            Text("Your saved entries will appear here.")
                        }
                    } else {
                        ForEach(filteredRecords) { record in
                            BeanStockPage3RecordRow(record: record, bagName: bagName(for: record.bagID))
                                .swipeActions {
                                    Button(role: .destructive) {
                                        delete(record)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                } header: {
                    Text("Recent Entries")
                }
                
                Section {
                    Color.clear
                        .frame(height: 96)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Bean Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddBag = true
                    } label: {
                        Label("Add Bag", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddBag) {
                BeanStockPage3AddBagSheet()
                    .environmentObject(store)
            }
            .onAppear {
                ensureBagSelection()
            }
            .onChange(of: store.bags.count) { _ in
                ensureBagSelection()
            }
            .alert("Invalid Entry", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
            .alert("Entry Saved", isPresented: $showSaveConfirmation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your entry was added and inventory is up to date.")
            }
        }
    }
    
    private func recordTypeName(_ type: BeanStockRecordType) -> String {
        let raw = type.rawValue.lowercased()
        if raw.contains("brew") { return "Brew" }
        if raw.contains("purchase") { return "Purchase" }
        if raw.contains("stock") || raw.contains("in") { return "Stock In" }
        if raw.contains("adjust") { return "Adjustment" }
        return type.rawValue.capitalized
    }
    
    private func ensureBagSelection() {
        if !store.bags.contains(where: { $0.id == selectedBagID }), let first = store.bags.first {
            selectedBagID = first.id
        }
    }
    
    func bagName(for id: UUID) -> String {
        store.bags.first(where: { $0.id == id })?.name ?? "Unknown Bag"
    }
    
    private func saveEntry() {
        guard let bag = selectedBag, amountGrams > 0 else {
            validationMessage = "Select a coffee bag and enter an amount greater than zero."
            showValidationAlert = true
            return
        }
        
        if isBrewType && amountGrams > bag.stockWeightGrams {
            validationMessage = "Amount exceeds current stock for \(bag.name)."
            showValidationAlert = true
            return
        }
        
        if let index = store.bags.firstIndex(where: { $0.id == bag.id }) {
            if isBrewType {
                store.bags[index].stockWeightGrams = max(0, store.bags[index].stockWeightGrams - amountGrams)
            } else {
                store.bags[index].stockWeightGrams += amountGrams
            }
        }
        
        let record = BeanStockRecord(
            id: UUID(),
            bagID: bag.id,
            date: date,
            type: recordType,
            amountGrams: amountGrams,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            method: method,
            grindSize: grindSize,
            waterAmountMl: waterAmountMl,
            rating: rating
        )
        
        store.records.append(record)
        store.save()
        
        note = ""
        amountGrams = 18.0
        date = Date()
        showSaveConfirmation = true
    }
    
    func delete(_ record: BeanStockRecord) {
        let isBrew = record.type.rawValue.lowercased().contains("brew")
        
        if let bagIndex = store.bags.firstIndex(where: { $0.id == record.bagID }) {
            if isBrew {
                store.bags[bagIndex].stockWeightGrams += record.amountGrams
            } else {
                store.bags[bagIndex].stockWeightGrams = max(0, store.bags[bagIndex].stockWeightGrams - record.amountGrams)
            }
        }
        
        if let recordIndex = store.records.firstIndex(where: { $0.id == record.id }) {
            store.records.remove(at: recordIndex)
            store.save()
        }
    }
}

private struct BeanStockPage3SummaryCard: View {
    let totalBags: Int
    let totalStock: Double
    let todayBrewGrams: Double
    let recentDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Total Stock", systemImage: "bag.fill")
                Spacer()
                Text("\(totalBags) bags / \(String(format: "%.1f g", totalStock))")
                    .font(.title2.weight(.semibold))
            }
            
            HStack {
                Label("Brewed Today", systemImage: "cup.and.saucer.fill")
                Spacer()
                Text(String(format: "%.1f g", todayBrewGrams))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("Last Entry", systemImage: "clock")
                Spacer()
                Text(recentDate.map { BeanStockPage3Format.shortDate($0) } ?? "No entries")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct BeanStockPage3RecordRow: View {
    let record: BeanStockRecord
    let bagName: String
    
    private var isBrew: Bool {
        record.type.rawValue.lowercased().contains("brew")
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isBrew ? "cup.and.saucer.fill" : "shippingbox.fill")
                .font(.title3)
                .foregroundStyle(isBrew ? Color.brown : Color.green)
                .frame(width: 36, height: 36)
                .background(.thinMaterial, in: Circle())
            
            VStack(alignment: .leading, spacing: 3) {
                Text(bagName)
                    .font(.headline)
                Text(BeanStockPage3Format.recordDate(record.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(record.note)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "%.1f g", record.amountGrams))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isBrew ? Color.red : Color.green)
                Text(record.method)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: index < record.rating ? "star.fill" : "star")
                            .font(.system(size: 9))
                            .foregroundStyle(index < record.rating ? Color.yellow : Color.gray)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

private struct BeanStockPage3AddBagSheet: View {
    @EnvironmentObject private var store: BeanStockStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var origin = ""
    @State private var roaster = ""
    @State private var roastLevel = "Medium"
    @State private var flavorNotes = ""
    @State private var stockWeightGrams = 250.0
    @State private var capacityWeightGrams = 250.0
    @State private var purchaseDate = Date()
    @State private var openedDate: Date? = Date()
    @State private var isFavorite = false

    private let roastLevels = ["Light", "Medium", "Dark", "Espresso", "Omni"]

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && stockWeightGrams > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Bag Details") {
                    TextField("Name", text: $name)
                    TextField("Origin", text: $origin)
                    TextField("Roaster", text: $roaster)
                    Picker("Roast Level", selection: $roastLevel) {
                        ForEach(roastLevels, id: \.self) { Text($0) }
                    }
                    TextField("Flavor Notes", text: $flavorNotes)
                }

                Section("Stock") {
                    HStack {
                        Text("Stock Weight (g)")
                        Spacer()
                        TextField("0", value: $stockWeightGrams, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    HStack {
                        Text("Capacity (g)")
                        Spacer()
                        TextField("0", value: $capacityWeightGrams, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                Section("Dates") {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    DatePicker(
                        "Opened Date",
                        selection: Binding<Date>(
                            get: { openedDate ?? purchaseDate },
                            set: { openedDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                    Toggle("Favorite", isOn: $isFavorite)
                }
            }
            .navigationTitle("Add Coffee Bag")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBag()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    private func saveBag() {
        let bag = BeanStockCoffeeBag(id: UUID(), name: name.trimmingCharacters(in: .whitespacesAndNewlines), origin: origin.trimmingCharacters(in: .whitespacesAndNewlines), roaster: roaster.trimmingCharacters(in: .whitespacesAndNewlines), roastLevel: roastLevel, flavorNotes: flavorNotes.trimmingCharacters(in: .whitespacesAndNewlines), stockWeightGrams: stockWeightGrams, capacityWeightGrams: capacityWeightGrams, purchaseDate: purchaseDate, openedDate: openedDate, isFavorite: isFavorite, fill: "")
        store.bags.append(bag)
        store.save()
        dismiss()
    }
}