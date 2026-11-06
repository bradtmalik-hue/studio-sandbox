import SwiftUI
import Combine

private let AppPage1ExpiryFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "yyyy年M月d日"
    return formatter
}()

private let AppPage1ShortExpiryFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M月d日"
    return formatter
}()

private func AppPage1DaysUntil(_ date: Date) -> Int? {
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: Date())
    let end = calendar.startOfDay(for: date)
    let components = calendar.dateComponents([.day], from: start, to: end)
    return components.day
}

struct AppPage1View: View {
    @EnvironmentObject private var store: AppMedicineStore
    @State private var searchText = ""
    @State private var selectedCategory = "全部"
    @State private var showingAddSheet = false
    @State private var selectedMedicine: AppMedicine?

    var filteredMedicines: [AppMedicine] {
        let sorted = store.medicines.sorted { $0.expiryDate < $1.expiryDate }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return sorted.filter { medicine in
            let categoryMatch = selectedCategory == "全部" || medicine.category == selectedCategory
            let searchMatch = query.isEmpty ||
                medicine.name.localizedCaseInsensitiveContains(query) ||
                medicine.location.localizedCaseInsensitiveContains(query) ||
                medicine.category.localizedCaseInsensitiveContains(query) ||
                medicine.manufacturer.localizedCaseInsensitiveContains(query) ||
                medicine.notes.localizedCaseInsensitiveContains(query)
            return categoryMatch && searchMatch
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.medicines.isEmpty {
                    AppPage1EmptyView(showingAddSheet: $showingAddSheet)
                } else if filteredMedicines.isEmpty {
                    AppPage1NoResultsView {
                        searchText = ""
                        selectedCategory = "全部"
                    }
                } else {
                    List {
                        AppPage1SummaryCard(medicines: filteredMedicines)
                        AppPage1FilterControls(categories: $selectedCategory, medicine: store.categories)
                        ForEach(filteredMedicines) { medicine in
                            Button {
                                selectedMedicine = medicine
                            } label: {
                                AppPage1Row(medicine: medicine)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button(role: .destructive) {
                                    delete(medicine)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("药品列表")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("添加", systemImage: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索药名、位置或分类")
            .sheet(isPresented: $showingAddSheet) {
                AppPage1AddSheet()
            }
            .sheet(item: $selectedMedicine) { medicine in
                AppPage1DetailView(medicine: medicine)
            }
        }
    }

    func delete(_ medicine: AppMedicine) {
        withAnimation {
            store.medicines.removeAll { $0.id == medicine.id }
            store.save()
        }
    }
}

struct AppPage1SummaryCard: View {
    let medicines: [AppMedicine]

    var totalQuantity: Int {
        medicines.reduce(0) { $0 + $1.quantity }
    }

    private var nearestExpiry: Date? {
        medicines.first?.expiryDate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(medicines.count) 种药")
                        .font(.title2.bold())
                    Text("合计 \(totalQuantity) 件")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("最近效期")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let date = nearestExpiry {
                        Text(AppPage1ShortExpiryFormatter.string(from: date))
                            .font(.headline)
                            .foregroundStyle(date < Date() ? .red : .primary)
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct AppPage1FilterControls: View {
    @Binding var selectedCategory: String
    let categories: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("分类", selection: $selectedCategory) {
                Text("全部").tag("全部")
                ForEach(categories, id: \.self) { category in
                    Text(category).tag(category)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 4)
    }
}

struct AppPage1Row: View {
    let medicine: AppMedicine

    private var expiryColor: Color {
        guard let days = AppPage1DaysUntil(medicine.expiryDate) else { return .primary }
        if days < 0 { return .red }
        if days <= 30 { return .orange }
        return .primary
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(medicine.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if medicine.isOpened {
                        Text("已开封")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12), in: Capsule())
                            .foregroundStyle(.blue)
                    }
                }
                Text("\(medicine.specification) · \(medicine.manufacturer)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 10) {
                    Label(medicine.location, systemImage: "location")
                    Label("\(medicine.quantity)\(medicine.unit)", systemImage: "shippingbox")
                    Label(medicine.category, systemImage: "tag")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(AppPage1ExpiryFormatter.string(from: medicine.expiryDate))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(expiryColor)
                if let days = AppPage1DaysUntil(medicine.expiryDate), days <= 30 && days >= 0 {
                    Text("\(days)天后到期")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if let days = AppPage1DaysUntil(medicine.expiryDate), days < 0 {
                    Text("已过期")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

struct AppPage1EmptyView: View {
    @Binding var showingAddSheet: Bool

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "pills")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("药箱还是空的")
                .font(.title3.bold())
            Text("把家里的药登记进来，有效期和位置一目了然。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                showingAddSheet = true
            } label: {
                Label("添加第一盒药", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondary.opacity(0.04))
    }
}

struct AppPage1NoResultsView: View {
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("没有找到符合条件的药")
                .font(.title3.bold())
            Text("试试其他关键词或切换分类筛选。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("清除筛选", action: onClear)
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.accentColor, in: Capsule())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondary.opacity(0.04))
    }
}

struct AppPage1AddSheet: View {
    @EnvironmentObject private var store: AppMedicineStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var specification = ""
    @State private var manufacturer = ""
    @State private var category = "未分类"
    @State private var location = "客厅药箱"
    @State private var quantity = 1
    @State private var unit = "盒"
    @State private var expiryDate = Calendar.current.date(byAdding: .month, value: 12, to: Date()) ?? Date()
    @State private var isOpened = false
    @State private var notes = ""

    var availableCategories: [String] {
        var cats = store.categories
        if !cats.contains("未分类") { cats.append("未分类") }
        return cats
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && quantity > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("药名", text: $name)
                    TextField("规格，如 0.5g×20片", text: $specification)
                    TextField("厂家", text: $manufacturer)
                }
                Section("分类与位置") {
                    Picker("分类", selection: $category) {
                        ForEach(availableCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    TextField("存放位置，如 客厅药箱第2层", text: $location)
                }
                Section("数量与效期") {
                    Stepper("数量：\(quantity) \(unit)", value: $quantity, in: 1...999)
                    TextField("单位", text: $unit)
                    DatePicker("有效期", selection: $expiryDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                }
                Section("状态") {
                    Toggle("已开封", isOn: $isOpened)
                }
                Section("备注") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("添加一盒药")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { addMedicine() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func addMedicine() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, quantity > 0 else { return }
        let medicine = AppMedicine(
            id: UUID(),
            name: trimmedName,
            specification: specification.trimmingCharacters(in: .whitespacesAndNewlines),
            manufacturer: manufacturer.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            quantity: quantity,
            unit: unit.trimmingCharacters(in: .whitespacesAndNewlines),
            expiryDate: expiryDate,
            isOpened: isOpened,
            notes: notes,
            createdAt: Date()
        )
        store.medicines.append(medicine)
        if !store.categories.contains(category) {
            store.categories.append(category)
        }
        store.save()
        dismiss()
    }
}

struct AppPage1DetailView: View {
    @EnvironmentObject private var store: AppMedicineStore
    @Environment(\.dismiss) private var dismiss

    let medicine: AppMedicine

    @State private var name: String
    @State private var specification: String
    @State private var manufacturer: String
    @State private var category: String
    @State private var location: String
    @State private var quantity: Int
    @State private var unit: String
    @State private var expiryDate: Date
    @State private var isOpened: Bool
    @State private var notes: String
    @State private var showDiscardAlert = false

    init(medicine: AppMedicine) {
        self.medicine = medicine
        _name = State(initialValue: medicine.name)
        _specification = State(initialValue: medicine.specification)
        _manufacturer = State(initialValue: medicine.manufacturer)
        _category = State(initialValue: medicine.category)
        _location = State(initialValue: medicine.location)
        _quantity = State(initialValue: medicine.quantity)
        _unit = State(initialValue: medicine.unit)
        _expiryDate = State(initialValue: medicine.expiryDate)
        _isOpened = State(initialValue: medicine.isOpened)
        _notes = State(initialValue: medicine.notes)
    }

    var availableCategories: [String] {
        var cats = store.categories
        if !cats.contains("未分类") { cats.append("未分类") }
        if !cats.contains(medicine.category) { cats.append(medicine.category) }
        if !cats.contains(category) { cats.append(category) }
        return cats
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && quantity > 0
    }

    private var hasChanges: Bool {
        name != medicine.name ||
        specification != medicine.specification ||
        manufacturer != medicine.manufacturer ||
        category != medicine.category ||
        location != medicine.location ||
        quantity != medicine.quantity ||
        unit != medicine.unit ||
        expiryDate != medicine.expiryDate ||
        isOpened != medicine.isOpened ||
        notes != medicine.notes
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("药名", text: $name)
                    TextField("规格，如 0.5g×20片", text: $specification)
                    TextField("厂家", text: $manufacturer)
                }
                Section("分类与位置") {
                    Picker("分类", selection: $category) {
                        ForEach(availableCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    TextField("存放位置，如 客厅药箱第2层", text: $location)
                }
                Section("数量与效期") {
                    Stepper("数量：\(quantity) \(unit)", value: $quantity, in: 1...999)
                    TextField("单位", text: $unit)
                    DatePicker("有效期", selection: $expiryDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                }
                Section("状态") {
                    Toggle("已开封", isOn: $isOpened)
                }
                Section("备注") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
                Section {
                    Button(role: .destructive) {
                        deleteMedicine()
                    } label: {
                        Label("删除此药", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("编辑药品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if hasChanges {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveChanges() }
                        .disabled(!canSave || !hasChanges)
                }
            }
            .alert("放弃修改？", isPresented: $showDiscardAlert) {
                Button("继续编辑", role: .cancel) {}
                Button("放弃", role: .destructive) { dismiss() }
            } message: {
                Text("更改尚未保存，确定要离开吗？")
            }
        }
    }

    private func saveChanges() {
        guard let index = store.medicines.firstIndex(where: { $0.id == medicine.id }) else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, quantity > 0 else { return }
        let updated = AppMedicine(
            id: medicine.id,
            name: trimmedName,
            specification: specification.trimmingCharacters(in: .whitespacesAndNewlines),
            manufacturer: manufacturer.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            quantity: quantity,
            unit: unit.trimmingCharacters(in: .whitespacesAndNewlines),
            expiryDate: expiryDate,
            isOpened: isOpened,
            notes: notes,
            createdAt: medicine.createdAt
        )
        store.medicines[index] = updated
        if !store.categories.contains(category) {
            store.categories.append(category)
        }
        store.save()
        dismiss()
    }

    private func deleteMedicine() {
        store.medicines.removeAll { $0.id == medicine.id }
        store.save()
        dismiss()
    }
}