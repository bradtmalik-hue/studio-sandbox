import SwiftUI

struct BeanStockPage2View: View {
    @EnvironmentObject private var store: BeanStockStore
    @State private var selectedBagID: UUID?
    @State private var showingEditBag = false
    @State private var editBag: BeanStockCoffeeBag?
    
    private var currentBag: BeanStockCoffeeBag? {
        if let id = selectedBagID, let bag = store.bags.first(where: { $0.id == id }) {
            return bag
        }
        return store.bags.first
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let bag = currentBag {
                    List {
                        Section {
                            bagPicker
                            if let bag = currentBag {
                                BeanStockPage2BagCard(bag: bag)
                            }
                        }
                        
                        Section {
                            if let bag = currentBag {
                                recordsSection(for: bag)
                            }
                        }
                        
                        Section {
                            Color.clear.frame(height: 96)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                    .navigationTitle("Bean Details")
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                if let bag = currentBag {
                                    editBag = bag
                                    showingEditBag = true
                                }
                            } label: {
                                Label("Edit Bean", systemImage: "pencil")
                            }
                        }
                    }
                    .sheet(isPresented: $showingEditBag) {
                        if let bag = editBag {
                            BeanStockPage2EditBagView(bag: bag)
                        }
                    }
                } else {
                    BeanStockPage2EmptyState()
                        .navigationTitle("Bean Details")
                }
            }
        }
        .onAppear {
            if selectedBagID == nil {
                selectedBagID = store.bags.first?.id
            }
        }
        .onChange(of: store.bags.count) { _, _ in
            if selectedBagID == nil, let first = store.bags.first {
                selectedBagID = first.id
            }
        }
    }
    
    private var bagPicker: some View {
        Picker("Select Bean", selection: $selectedBagID) {
            ForEach(store.bags) { bag in
                Text(bag.name).tag(Optional(bag.id))
            }
        }
        .pickerStyle(.menu)
        .font(.subheadline)
        .textCase(nil)
    }
    
    private func recordsSection(for bag: BeanStockCoffeeBag) -> some View {
        let records = store.records
            .filter { $0.bagID == bag.id }
            .sorted { $0.date > $1.date }
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Brewing Records")
                    .font(.headline)
                Spacer()
                Text("\(records.count) records")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)
            
            if records.isEmpty {
                ContentUnavailableView(
                    "No Records",
                    systemImage: "cup.and.saucer",
                    description: Text("No brewing records for this bean yet.")
                )
                .frame(maxWidth: .infinity)
            } else {
                ForEach(records) { record in
                    BeanStockPage2RecordRow(record: record)
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                if let idx = store.records.firstIndex(where: { $0.id == record.id }) {
                                    store.records.remove(at: idx)
                                    store.save()
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct BeanStockPage2BagCard: View {
    let bag: BeanStockCoffeeBag
    @EnvironmentObject private var store: BeanStockStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bag.name)
                        .font(.title3.bold())
                    Text("\(bag.origin) · \(bag.roaster)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    if let idx = store.bags.firstIndex(where: { $0.id == bag.id }) {
                        store.bags[idx].isFavorite.toggle()
                        store.save()
                    }
                } label: {
                    Image(systemName: bag.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(bag.isFavorite ? .yellow : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.borderless)
            }
            
            Divider()
            
            VStack(spacing: 8) {
                HStack {
                    Label("Roast", systemImage: "flame")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(bag.roastLevel)
                        .font(.subheadline)
                }
                HStack {
                    Label("Stock", systemImage: "scalemass")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.0f g / %.0f g", bag.stockWeightGrams, bag.capacityWeightGrams))
                        .font(.subheadline.monospacedDigit())
                }
                HStack {
                    Label("Purchased", systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Self.dateFormatter.string(from: bag.purchaseDate))
                        .font(.subheadline)
                }
                if let opened = bag.openedDate {
                    HStack {
                        Label("Opened", systemImage: "calendar.badge.clock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Self.dateFormatter.string(from: opened))
                            .font(.subheadline)
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Label("Flavor Notes", systemImage: "text.quote")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(bag.flavorNotes)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
}

struct BeanStockPage2RecordRow: View {
    let record: BeanStockRecord
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.method)
                    .font(.body.weight(.medium))
                Text(Self.dateFormatter.string(from: record.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.0f g", record.amountGrams))
                    .font(.body.monospacedDigit())
                if record.waterAmountMl > 0 {
                    Text(String(format: "%.0f ml", record.waterAmountMl))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < record.rating ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter
    }()
}

struct BeanStockPage2EmptyState: View {
    var body: some View {
        ContentUnavailableView(
            "No Beans Yet",
            systemImage: "bag",
            description: Text("Add your first coffee bean to see details and brewing records.")
        )
    }
}

struct BeanStockPage2EditBagView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: BeanStockStore
    let bag: BeanStockCoffeeBag
    
    @State private var name: String
    @State private var origin: String
    @State private var roaster: String
    @State private var roastLevel: String
    @State private var flavorNotes: String
    @State private var stockWeightGrams: Double
    @State private var capacityWeightGrams: Double
    @State private var purchaseDate: Date
    @State private var openedDate: Date?
    @State private var isFavorite: Bool
    @State private var showValidationAlert = false
    
    init(bag: BeanStockCoffeeBag) {
        self.bag = bag
        _name = State(initialValue: bag.name)
        _origin = State(initialValue: bag.origin)
        _roaster = State(initialValue: bag.roaster)
        _roastLevel = State(initialValue: bag.roastLevel)
        _flavorNotes = State(initialValue: bag.flavorNotes)
        _stockWeightGrams = State(initialValue: bag.stockWeightGrams)
        _capacityWeightGrams = State(initialValue: bag.capacityWeightGrams)
        _purchaseDate = State(initialValue: bag.purchaseDate)
        _openedDate = State(initialValue: bag.openedDate)
        _isFavorite = State(initialValue: bag.isFavorite)
    }
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !origin.trimmingCharacters(in: .whitespaces).isEmpty &&
        !roaster.trimmingCharacters(in: .whitespaces).isEmpty &&
        !roastLevel.trimmingCharacters(in: .whitespaces).isEmpty &&
        stockWeightGrams >= 0 &&
        capacityWeightGrams > 0 &&
        stockWeightGrams <= capacityWeightGrams
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Bean Information") {
                    TextField("Name", text: $name)
                    TextField("Origin", text: $origin)
                    TextField("Roaster", text: $roaster)
                    TextField("Roast Level", text: $roastLevel)
                    TextField("Flavor Notes", text: $flavorNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Stock") {
                    HStack {
                        Text("Current Weight (g)")
                        Spacer()
                        TextField("0", value: $stockWeightGrams, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    HStack {
                        Text("Capacity (g)")
                        Spacer()
                        TextField("0", value: $capacityWeightGrams, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                
                Section("Dates") {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    Toggle("Opened", isOn: Binding(
                        get: { openedDate != nil },
                        set: { newValue in
                            if newValue {
                                openedDate = openedDate ?? Date()
                            } else {
                                openedDate = nil
                            }
                        }
                    ))
                    if openedDate != nil {
                        DatePicker("Opened Date", selection: Binding(
                            get: { openedDate ?? Date() },
                            set: { openedDate = $0 }
                        ), displayedComponents: .date)
                    }
                }
                
                Section {
                    Toggle("Favorite", isOn: $isFavorite)
                }
            }
            .navigationTitle("Edit Bean")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isFormValid {
                            saveChanges()
                            dismiss()
                        } else {
                            showValidationAlert = true
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Invalid Input", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please fill in all required fields and ensure stock weight is between 0 and capacity.")
            }
        }
    }
    
    private func saveChanges() {
        guard let idx = store.bags.firstIndex(where: { $0.id == bag.id }) else { return }
        store.bags[idx].name = name.trimmingCharacters(in: .whitespaces)
        store.bags[idx].origin = origin.trimmingCharacters(in: .whitespaces)
        store.bags[idx].roaster = roaster.trimmingCharacters(in: .whitespaces)
        store.bags[idx].roastLevel = roastLevel.trimmingCharacters(in: .whitespaces)
        store.bags[idx].flavorNotes = flavorNotes.trimmingCharacters(in: .whitespaces)
        store.bags[idx].stockWeightGrams = stockWeightGrams
        store.bags[idx].capacityWeightGrams = capacityWeightGrams
        store.bags[idx].purchaseDate = purchaseDate
        store.bags[idx].openedDate = openedDate
        store.bags[idx].isFavorite = isFavorite
        store.save()
    }
}