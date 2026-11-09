import SwiftUI

struct BeanStockPage1View: View {
    @EnvironmentObject var store: BeanStockStore
    @State private var searchText = ""
    @State private var selectedRoastFilter = "All"
    @State private var showingAddSheet = false

    private var uniqueRoastLevels: [String] {
        var levels = Array(Set(store.bags.map { $0.roastLevel })).sorted()
        levels.insert("All", at: 0)
        return levels
    }

    private var filteredBags: [BeanStockCoffeeBag] {
        var bags = store.bags
        if !searchText.isEmpty {
            bags = bags.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.origin.localizedCaseInsensitiveContains(searchText) ||
                $0.roaster.localizedCaseInsensitiveContains(searchText)
            }
        }
        if selectedRoastFilter != "All" {
            bags = bags.filter { $0.roastLevel.lowercased() == selectedRoastFilter.lowercased() }
        }
        return bags
    }

    var totalStockGrams: Double {
        filteredBags.reduce(0) { $0 + $1.stockWeightGrams }
    }

    private var mostRecentDateText: String {
        guard let date = store.bags.map({ $0.openedDate ?? $0.purchaseDate }).max() else {
            return "No activity"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    BeanStockPage1SummaryCard(
                        bagCount: filteredBags.count,
                        totalGrams: totalStockGrams,
                        lastActivity: mostRecentDateText
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section {
                    BeanStockPage1SearchFilterBar(roastLevels: uniqueRoastLevels)
                }

                if filteredBags.isEmpty {
                    BeanStockPage1EmptyView(addAction: { showingAddSheet = true })
                } else {
                    Section {
                        ForEach(filteredBags) { bag in
                            NavigationLink(destination: BeanStockPage1DetailView(bag: bag)) {
                                BeanStockPage1Row(bag: bag)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(bag)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("Bean Stock")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                BeanStockPage1AddSheet()
            }
        }
    }

    func delete(_ bag: BeanStockCoffeeBag) {
        store.bags.removeAll { $0.id == bag.id }
        store.records.removeAll { $0.bagID == bag.id }
        store.save()
    }
}

struct BeanStockPage1SummaryCard: View {
    let bagCount: Int
    let totalGrams: Double
    let lastActivity: String

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bags")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(bagCount)")
                    .font(.title2.bold())
            }
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Stock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(totalGrams, specifier: "%.0f") g")
                    .font(.title2.bold())
            }
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text("Last Activity")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(lastActivity)
                    .font(.subheadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct BeanStockPage1SearchFilterBar: View {
    @Binding var searchText: String
    @Binding var selectedRoastFilter: String
    let roastLevels: [String]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search name, origin, roaster", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.tertiarySystemFill))
            )

            Picker("Roast Level", selection: $selectedRoastFilter) {
                ForEach(roastLevels, id: \.self) { level in
                    Text(level).tag(level)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 4)
    }
}

struct BeanStockPage1Row: View {
    let bag: BeanStockCoffeeBag

    private var stockPercentage: Double {
        guard bag.capacityWeightGrams > 0 else { return 0 }
        return min(max(bag.stockWeightGrams / bag.capacityWeightGrams, 0), 1)
    }

    private var openedText: String {
        if let opened = bag.openedDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "MMM d"
            return "Opened \(formatter.string(from: opened))"
        } else {
            return "Not opened"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(bag.name)
                    .font(.headline)
                HStack(spacing: 8) {
                    Text(bag.origin)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(bag.roastLevel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    Text("\(String(format: "%.0f", bag.stockWeightGrams))g / \(String(format: "%.0f", bag.capacityWeightGrams))g")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(openedText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                if bag.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                        .font(.subheadline)
                }
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemFill))
                        .frame(width: 60, height: 6)
                    Capsule()
                        .fill(stockPercentage < 0.2 ? Color.red : Color.accentColor)
                        .frame(width: 60 * stockPercentage, height: 6)
                }
                Text("\(Int(stockPercentage * 100))%")
                    .font(.caption2)
                    .foregroundStyle(stockPercentage < 0.2 ? .red : .secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct BeanStockPage1EmptyView: View {
    let addAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No Coffee Bags")
                .font(.title3.bold())
            Text("Add your first bag to start tracking your beans.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: addAction) {
                Label("Add First Bag", systemImage: "plus.circle.fill")
                    .font(.body.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct BeanStockPage1DetailView: View {
    @EnvironmentObject var store: BeanStockStore
    @Environment(\.dismiss) private var dismiss
    let bag: BeanStockCoffeeBag

    @State private var showingDeleteConfirmation = false

    private var bagRecords: [BeanStockRecord] {
        store.records.filter { $0.bagID == bag.id }
            .sorted { $0.date > $1.date }
    }

    private var purchaseDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: bag.purchaseDate)
    }

    private var openedDateText: String {
        guard let opened = bag.openedDate else { return "Not opened yet" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: opened)
    }

    var body: some View {
        List {
            Section("Bean Details") {
                LabeledContent("Name", value: bag.name)
                LabeledContent("Origin", value: bag.origin)
                LabeledContent("Roaster", value: bag.roaster)
                LabeledContent("Roast Level", value: bag.roastLevel)
                LabeledContent("Flavor Notes", value: bag.flavorNotes)
                LabeledContent("Purchase Date", value: purchaseDateText)
                LabeledContent("Opened Date", value: openedDateText)
                LabeledContent("Stock", value: "\(String(format: "%.0f", bag.stockWeightGrams))g / \(String(format: "%.0f", bag.capacityWeightGrams))g")
                Toggle("Favorite", isOn: Binding(
                    get: { bag.isFavorite },
                    set: { newValue in
                        if let index = store.bags.firstIndex(where: { $0.id == bag.id }) {
                            store.bags[index].isFavorite = newValue
                            store.save()
                        }
                    }
                ))
                .tint(.pink)
            }

            Section("Brew History (\(bagRecords.count))") {
                if bagRecords.isEmpty {
                    Text("No brew records yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(bagRecords) { record in
                        BeanStockPage1RecordRow(record: record)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete This Bag", systemImage: "trash")
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle(bag.name)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this bag and its records?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteBag()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    func deleteBag() {
        store.bags.removeAll { $0.id == bag.id }
        store.records.removeAll { $0.bagID == bag.id }
        store.save()
        dismiss()
    }
}

struct BeanStockPage1RecordRow: View {
    let record: BeanStockRecord

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: record.date)
    }

    private var typeText: String {
        record.type == .in ? "Inbound" : "Brew"
    }

    var body: some View {
        HStack {
            Image(systemName: record.type == .in ? "arrow.down.circle.fill" : "cup.and.saucer.fill")
                .foregroundStyle(record.type == .in ? .green : .blue)
                .font(.title3)
            VStack(alignment: .leading) {
                Text(typeText)
                    .font(.subheadline.bold())
                Text(dateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Text("\(String(format: "%.1f", record.amountGrams))g")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(record.type == .in ? .green : .primary)
        }
        .padding(.vertical, 2)
    }
}

struct BeanStockPage1AddSheet: View {
    @EnvironmentObject var store: BeanStockStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var origin = ""
    @State private var roaster = ""
    @State private var roastLevel = "Light"
    @State private var flavorNotes = ""
    @State private var capacityWeightGrams = "250"
    @State private var stockWeightGrams = "250"
    @State private var purchaseDate = Date()
    @State private var isOpened = false
    @State private var openedDate = Date()
    @State private var isFavorite = false

    private let roastLevels = ["Light", "Medium", "Dark", "Medium-Dark", "City Roast"]

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (Double(capacityWeightGrams) ?? 0) > 0 &&
        (Double(stockWeightGrams) ?? 0) >= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Bean Information") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    TextField("Origin", text: $origin)
                    TextField("Roaster", text: $roaster)
                    Picker("Roast Level", selection: $roastLevel) {
                        ForEach(roastLevels, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                    TextField("Flavor Notes", text: $flavorNotes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Weights") {
                    TextField("Capacity (g)", text: $capacityWeightGrams)
                        .keyboardType(.decimalPad)
                    TextField("Current Stock (g)", text: $stockWeightGrams)
                        .keyboardType(.decimalPad)
                }

                Section("Dates") {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    Toggle("Opened", isOn: $isOpened)
                    if isOpened {
                        DatePicker("Opened Date", selection: $openedDate, displayedComponents: .date)
                    }
                }

                Section {
                    Toggle("Favorite", isOn: $isFavorite)
                        .tint(.pink)
                }
            }
            .navigationTitle("Add Coffee Bag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    func save() {
        let capacity = Double(capacityWeightGrams) ?? 0
        let stock = Double(stockWeightGrams) ?? 0
        let newBag = BeanStockCoffeeBag(id: UUID(), name: name.trimmingCharacters(in: .whitespacesAndNewlines), origin: origin.trimmingCharacters(in: .whitespacesAndNewlines), roaster: roaster.trimmingCharacters(in: .whitespacesAndNewlines), roastLevel: roastLevel, flavorNotes: flavorNotes.trimmingCharacters(in: .whitespacesAndNewlines), stockWeightGrams: min(stock, capacity), capacityWeightGrams: capacity, purchaseDate: purchaseDate, openedDate: isOpened ? openedDate : nil, isFavorite: isFavorite, fill: "")
        store.bags.append(newBag)
        store.save()
        dismiss()
    }
}