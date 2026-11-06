import SwiftUI

extension DateFormatter {
    static let medicineList: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()
}

struct AppPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if reduceMotion {
            configuration.label
                .opacity(configuration.isPressed ? 0.9 : 1)
                .animation(.easeIn(duration: 0.1), value: configuration.isPressed)
        } else {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .opacity(configuration.isPressed ? 0.9 : 1)
                .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.9), value: configuration.isPressed)
        }
    }
}

struct AppMedicineRow: View {
    let medicine: AppMedicine

    private var statusColor: Color {
        if medicine.isExpired { return .red }
        if medicine.daysUntilExpiry <= 30 { return .orange }
        return .green
    }

    private var statusText: String {
        if medicine.isExpired {
            let days = abs(medicine.daysUntilExpiry)
            return days == 0 ? "已过期" : "已过期 \(days) 天"
        }
        return "\(medicine.daysUntilExpiry) 天"
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(medicine.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("\(medicine.category) · \(medicine.location)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(DateFormatter.medicineList.string(from: medicine.expiryDate))
                    .font(.caption)
                    .foregroundStyle(statusColor)
                    .monospacedDigit()
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                    .monospacedDigit()
                Text("×\(medicine.quantity)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 4)
    }
}

struct AppMedicineListView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingAdd = false
    @State private var selectedCategory = "全部"

    var categories: [String] {
        var set = Set(store.medicines.map(\.category))
        set.insert("全部")
        return Array(set).sorted()
    }

    private var filteredMedicines: [AppMedicine] {
        var result = store.medicines
        if !store.searchText.isEmpty {
            let query = store.searchText.localizedLowercase
            result = result.filter {
                $0.name.localizedLowercase.contains(query) ||
                $0.location.localizedLowercase.contains(query) ||
                $0.category.localizedLowercase.contains(query)
            }
        }
        if selectedCategory != "全部" {
            result = result.filter { $0.category == selectedCategory }
        }
        return result.sorted {
            if $0.isExpired != $1.isExpired {
                return !$0.isExpired
            }
            return $0.daysUntilExpiry < $1.daysUntilExpiry
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredMedicines.isEmpty {
                    ContentUnavailableView {
                        Label("药箱空空的", systemImage: "pills")
                    } description: {
                        Text("添加第一种药品，记录有效期和存放位置")
                    } actions: {
                        Button("添加药品") { showingAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(filteredMedicines) { medicine in
                        NavigationLink(value: medicine.id) {
                            AppMedicineRow(medicine: medicine)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        .buttonStyle(AppPressButtonStyle())
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                delete(medicine)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("家庭药箱")
            .searchable(text: $store.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索药品名称、位置")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("药品分类筛选")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(AppPressButtonStyle())
                    .accessibilityLabel("添加药品")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AppMedicineFormView(medicine: nil)
                    .presentationDetents([.medium, .large])
            }
            .navigationDestination(for: UUID.self) { id in
                if let medicine = store.medicines.first(where: { $0.id == id }) {
                    AppMedicineDetailView(medicine: medicine)
                }
            }
            .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.9), value: filteredMedicines.map(\.id))
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }

    func delete(_ medicine: AppMedicine) {
        withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.9)) {
            store.medicines.removeAll { $0.id == medicine.id }
        }
        store.save()
    }
}

struct AppMedicineDetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let medicine: AppMedicine
    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false

    private var displayMedicine: AppMedicine {
        store.medicines.first(where: { $0.id == medicine.id }) ?? medicine
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                infoGrid
                if !displayMedicine.notes.isEmpty {
                    notesSection
                }
            }
            .padding(20)
        }
        .navigationTitle("药品详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("编辑") { showingEdit = true }
                    .buttonStyle(AppPressButtonStyle())
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(role: .destructive) {
                showingDeleteConfirm = true
            } label: {
                Text("删除药品")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding()
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $showingEdit) {
            AppMedicineFormView(medicine: displayMedicine)
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog("确定要删除这盒药吗？", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("删除", role: .destructive) { deleteMedicine() }
            Button("取消", role: .cancel) { }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(displayMedicine.name)
                    .font(.largeTitle)
                    .tracking(-0.4)
                Text(displayMedicine.category)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if displayMedicine.isExpired {
                Text("已过期")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.red.opacity(0.15)))
                    .foregroundStyle(.red)
            } else {
                Text("\(displayMedicine.daysUntilExpiry) 天")
                    .font(.caption)
                    .monospacedDigit()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.green.opacity(0.15)))
                    .foregroundStyle(.green)
            }
        }
    }

    private var infoGrid: some View {
        VStack(spacing: 12) {
            infoRow(label: "有效期至", value: DateFormatter.medicineList.string(from: displayMedicine.expiryDate))
            Divider()
            infoRow(label: "存放位置", value: displayMedicine.location)
            Divider()
            infoRow(label: "数量", value: "\(displayMedicine.quantity) 盒")
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(uiColor: .secondarySystemGroupedBackground)))
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("备注")
                .font(.headline)
            Text(displayMedicine.notes)
                .font(.body)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(uiColor: .secondarySystemGroupedBackground)))
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
    }

    private func deleteMedicine() {
        withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.9)) {
            store.medicines.removeAll { $0.id == medicine.id }
        }
        store.save()
        dismiss()
    }
}

struct AppMedicineFormView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let medicine: AppMedicine?

    @State private var name: String
    @State private var category: String
    @State private var expiryDate: Date
    @State private var location: String
    @State private var quantity: Int
    @State private var notes: String

    init(medicine: AppMedicine? = nil) {
        self.medicine = medicine
        _name = State(initialValue: medicine?.name ?? "")
        _category = State(initialValue: medicine?.category ?? "感冒用药")
        _expiryDate = State(initialValue: medicine?.expiryDate ?? Date().addingTimeInterval(90 * 24 * 60 * 60))
        _location = State(initialValue: medicine?.location ?? "")
        _quantity = State(initialValue: medicine?.quantity ?? 1)
        _notes = State(initialValue: medicine?.notes ?? "")
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var categoryOptions: [String] {
        var set = Set(store.medicines.map(\.category))
        for category in ["感冒用药", "退烧止痛", "肠胃用药", "过敏用药", "外用药", "维生素", "慢性病用药", "其他"] {
            set.insert(category)
        }
        return Array(set).sorted()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("药品名称", text: $name)
                    Picker("分类", selection: $category) {
                        ForEach(categoryOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    DatePicker("有效期至", selection: $expiryDate, displayedComponents: .date)
                }
                Section("存放位置与数量") {
                    TextField("存放位置", text: $location)
                    Stepper(value: $quantity, in: 0...999) {
                        HStack {
                            Text("数量")
                            Spacer()
                            Text("\(quantity) 盒")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("备注") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(medicine == nil ? "添加药品" : "编辑药品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .buttonStyle(AppPressButtonStyle())
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    save()
                } label: {
                    Text("保存")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(trimmedName.isEmpty)
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .interactiveDismissDisabled(true)
    }

    func save() {
        guard !trimmedName.isEmpty else { return }

        let newMedicine = AppMedicine(id: medicine?.id ?? UUID(), name: trimmedName, category: category.trimmingCharacters(in: .whitespacesAndNewlines), expiryDate: expiryDate, location: location.trimmingCharacters(in: .whitespacesAndNewlines), quantity: quantity, notes: notes.trimmingCharacters(in: .whitespacesAndNewlines), isExpired: false, daysUntilExpiry: 0)

        if let medicine {
            if let index = store.medicines.firstIndex(where: { $0.id == medicine.id }) {
                store.medicines[index] = newMedicine
            }
        } else {
            store.medicines.insert(newMedicine, at: 0)
        }

        store.save()
        dismiss()
    }
}