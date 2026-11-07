import SwiftUI
import Combine
import Foundation

struct AppPage1View: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var selectedCategory = "全部"
    @State private var selectedMedicine: AppMedicineBox?
    @State private var showingAddSheet = false

    private var categories: [String] {
        let base = Array(Set(store.medicines.map { $0.category })).sorted()
        return ["全部"] + base.filter { !$0.isEmpty }
    }

    private var sortedMedicines: [AppMedicineBox] {
        store.medicines.sorted { $0.expiryDate < $1.expiryDate }
    }

    var filteredMedicines: [AppMedicineBox] {
        sortedMedicines.filter { medicine in
            let matchesCategory = selectedCategory == "全部" || medicine.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                medicine.name.localizedCaseInsensitiveContains(searchText) ||
                medicine.category.localizedCaseInsensitiveContains(searchText) ||
                medicine.storageLocation.localizedCaseInsensitiveContains(searchText) ||
                medicine.notes.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    private var summaryText: String {
        let count = filteredMedicines.count
        let totalQuantity = filteredMedicines.reduce(0) { $0 + $1.quantity }
        let nearest = filteredMedicines.map(\.expiryDate).min()
        if let nearest = nearest {
            return "共 \(count) 盒 · 总数量 \(totalQuantity) · 最近到期 \(nearest.formatted(date: .numeric, time: .omitted))"
        }
        return "暂无可显示的药品"
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.medicines.isEmpty {
                    AppPage1EmptyState(originalMedicine: $showingAddSheet)
                } else {
                    VStack(spacing: 0) {
                        AppPage1SummaryCard(text: summaryText)
                        categoryPicker

                        if filteredMedicines.isEmpty {
                            ContentUnavailableView {
                                Label("未找到药品", systemImage: "magnifyingglass")
                            } description: {
                                Text("没有匹配「\(searchText)」的药品")
                            } actions: {
                                Button("清除搜索") {
                                    searchText = ""
                                }
                                .buttonStyle(.bordered)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(filteredMedicines, id: \.id) { medicine in
                                    Button {
                                        selectedMedicine = medicine
                                    } label: {
                                        AppPage1MedicineRow(medicine: medicine)
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
                }
            }
            .navigationTitle("药品列表")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索药名、位置、分类")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("添加药品")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AppPage1AddMedicineSheet()
            }
            .sheet(isPresented: Binding(
                get: { selectedMedicine != nil },
                set: { if !$0 { selectedMedicine = nil } }
            )) {
                if let medicine = selectedMedicine {
                    AppPage1DetailView(originalMedicine: medicine)
                }
            }
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12))
                            .foregroundStyle(selectedCategory == category ? Color.accentColor : Color.primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    func delete(_ medicine: AppMedicineBox) {
        withAnimation {
            store.medicines.removeAll { $0.id == medicine.id }
            store.save()
        }
    }
}

struct AppPage1SummaryCard: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pills.fill")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
            Text(text)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct AppPage1MedicineRow: View {
    let medicine: AppMedicineBox

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(medicine.name)
                        .font(.headline)
                    if !medicine.category.isEmpty {
                        Text(medicine.category)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.12), in: Capsule())
                    }
                }
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption)
                    Text(medicine.expiryDate.formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                }
                .foregroundStyle(expiryColor)
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(medicine.storageLocation)
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Image(systemName: "number.circle")
                        .font(.caption)
                    Text("\(medicine.quantity) \(medicine.unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    var expiryColor: Color {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: medicine.expiryDate).day ?? 0
        if days < 0 { return .red }
        if days <= 30 { return .orange }
        return .secondary
    }
}

struct AppPage1EmptyState: View {
    @Binding var showingAddSheet: Bool

    var body: some View {
        ContentUnavailableView {
            Label("家里还没有药品", systemImage: "pills.fill")
        } description: {
            Text("添加第一盒药，记录有效期和存放位置。")
        } actions: {
            Button("添加第一条") {
                showingAddSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct AppPage1DetailView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let originalMedicine: AppMedicineBox
    @State private var name: String
    @State private var category: String
    @State private var expiryDate: Date
    @State private var storageLocation: String
    @State private var quantity: Int
    @State private var unit: String
    @State private var reminderEnabled: Bool
    @State private var notes: String

    init(medicine: AppMedicineBox) {
        self.originalMedicine = medicine
        _name = State(initialValue: medicine.name)
        _category = State(initialValue: medicine.category)
        _expiryDate = State(initialValue: medicine.expiryDate)
        _storageLocation = State(initialValue: medicine.storageLocation)
        _quantity = State(initialValue: medicine.quantity)
        _unit = State(initialValue: medicine.unit)
        _reminderEnabled = State(initialValue: medicine.reminderEnabled)
        _notes = State(initialValue: medicine.notes)
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !storageLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        quantity > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("药名", text: $name)
                    TextField("分类（如感冒药）", text: $category)
                    DatePicker("有效期", selection: $expiryDate, displayedComponents: .date)
                }

                Section("存放与数量") {
                    TextField("存放位置", text: $storageLocation)
                    Stepper(value: $quantity, in: 1...999) {
                        Label("数量：\(quantity)", systemImage: "number.circle")
                    }
                    Picker("单位", selection: $unit) {
                        Text("盒").tag("盒")
                        Text("瓶").tag("瓶")
                        Text("袋").tag("袋")
                        Text("支").tag("支")
                        Text("片").tag("片")
                    }
                }

                Section("提醒") {
                    Toggle("到期前提醒", isOn: $reminderEnabled)
                }

                Section("备注") {
                    TextField("备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }

                if !isFormValid {
                    Section {
                        Label("请填写药名和存放位置，数量需大于 0", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("药品详情")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    func save() {
        if let index = store.medicines.firstIndex(where: { $0.id == originalMedicine.id }) {
            let updated = AppMedicineBox(
                id: originalMedicine.id,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category.trimmingCharacters(in: .whitespacesAndNewlines),
                expiryDate: expiryDate,
                storageLocation: storageLocation.trimmingCharacters(in: .whitespacesAndNewlines),
                quantity: quantity,
                unit: unit,
                reminderEnabled: reminderEnabled,
                notes: notes,
                createdAt: originalMedicine.createdAt
            )
            store.medicines[index] = updated
            store.save()
        }
        dismiss()
    }
}

struct AppPage1AddMedicineSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = ""
    @State private var expiryDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var storageLocation = ""
    @State private var quantity = 1
    @State private var unit = "盒"
    @State private var reminderEnabled = true
    @State private var notes = ""

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !storageLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        quantity > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("药名", text: $name)
                    TextField("分类（如感冒药）", text: $category)
                    DatePicker("有效期", selection: $expiryDate, displayedComponents: .date)
                }

                Section("存放与数量") {
                    TextField("存放位置", text: $storageLocation)
                    Stepper(value: $quantity, in: 1...999) {
                        Label("数量：\(quantity)", systemImage: "number.circle")
                    }
                    Picker("单位", selection: $unit) {
                        Text("盒").tag("盒")
                        Text("瓶").tag("瓶")
                        Text("袋").tag("袋")
                        Text("支").tag("支")
                        Text("片").tag("片")
                    }
                }

                Section("提醒") {
                    Toggle("到期前提醒", isOn: $reminderEnabled)
                }

                Section("备注") {
                    TextField("备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }

                if !isFormValid {
                    Section {
                        Label("请填写药名和存放位置，数量需大于 0", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("添加药品")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    func save() {
        let newMedicine = AppMedicineBox(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            expiryDate: expiryDate,
            storageLocation: storageLocation.trimmingCharacters(in: .whitespacesAndNewlines),
            quantity: quantity,
            unit: unit,
            reminderEnabled: reminderEnabled,
            notes: notes,
            createdAt: Date()
        )
        store.medicines.append(newMedicine)
        store.save()
        dismiss()
    }
}