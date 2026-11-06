import SwiftUI
import Foundation

enum AppDateText {
    static func expiry(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }

    static func added(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

enum AppMedicineEditMode {
    case add
    case edit(AppMedicine)
}

struct AppMedicineListView: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var selectedLocation: String? = nil
    @State private var showOnlyExpiring = false
    @State private var showingAdd = false

    var allLocations: [String] {
        Array(Set(store.medicines.map(\.location))).sorted()
    }

    private var filtered: [AppMedicine] {
        store.medicines
            .filter { medicine in
                if let selectedLocation = selectedLocation, medicine.location != selectedLocation {
                    return false
                }
                if showOnlyExpiring && !medicine.isExpired && medicine.daysUntilExpiry > 30 {
                    return false
                }
                if !searchText.isEmpty {
                    let query = searchText.lowercased()
                    let matches = medicine.name.lowercased().contains(query) ||
                        medicine.location.lowercased().contains(query) ||
                        medicine.specification.lowercased().contains(query)
                    if !matches {
                        return false
                    }
                }
                return true
            }
            .sorted { lhs, rhs in
                if lhs.isExpired != rhs.isExpired {
                    return lhs.isExpired
                }
                return lhs.daysUntilExpiry < rhs.daysUntilExpiry
            }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("搜索药品、位置或规格", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

                    Toggle("只显示 30 天内到期或已过期", isOn: $showOnlyExpiring)
                        .font(.subheadline)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            AppFilterChip(title: "全部", isSelected: selectedLocation == nil) {
                                selectedLocation = nil
                            }
                            ForEach(allLocations, id: \.self) { location in
                                AppFilterChip(title: location, isSelected: selectedLocation == location) {
                                    selectedLocation = location
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                if filtered.isEmpty {
                    Section {
                        AppMedicineEmptyStateView()
                    }
                } else {
                    Section {
                        ForEach(filtered) { medicine in
                            NavigationLink {
                                AppMedicineDetailView(medicine: medicine)
                            } label: {
                                AppMedicineRow(medicine: medicine)
                            }
                        }
                    }
                }
            }
            .navigationTitle("家庭药箱")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AppMedicineEditView(mode: .add)
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }
}

struct AppFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.primary.opacity(0.12) : Color.secondary.opacity(0.08), in: Capsule())
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
        }
        .buttonStyle(.plain)
    }
}

struct AppMedicineRow: View {
    let medicine: AppMedicine

    private var statusColor: Color {
        if medicine.isExpired {
            return .red
        }
        if medicine.daysUntilExpiry <= 30 {
            return .orange
        }
        return .green
    }

    private var statusText: String {
        if medicine.isExpired {
            let days = abs(medicine.daysUntilExpiry)
            return days == 0 ? "今天过期" : "已过期 \(days) 天"
        }
        if medicine.daysUntilExpiry <= 30 {
            return "\(medicine.daysUntilExpiry) 天后到期"
        }
        return "\(AppDateText.expiry(medicine.expiryDate)) 到期"
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(medicine.name)
                    .font(.headline)
                Text("\(medicine.specification) · \(medicine.quantity)\(medicine.unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                    Text(medicine.location)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                if medicine.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
                Text(AppDateText.expiry(medicine.expiryDate))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AppMedicineEmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "pills")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("药箱空空如也")
                .font(.headline)
            Text("点击右上角 + 添加药品，记录有效期和存放位置。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .listRowBackground(Color.clear)
    }
}

struct AppLocationView: View {
    @EnvironmentObject var store: AppStore

    var locations: [String] {
        Array(Set(store.medicines.map(\.location))).sorted()
    }

    func medicines(in location: String) -> [AppMedicine] {
        store.medicines
            .filter { $0.location == location }
            .sorted { lhs, rhs in
                if lhs.isExpired != rhs.isExpired {
                    return lhs.isExpired
                }
                return lhs.daysUntilExpiry < rhs.daysUntilExpiry
            }
    }

    var body: some View {
        NavigationStack {
            List {
                if locations.isEmpty {
                    Section {
                        AppLocationEmptyView()
                    }
                } else {
                    ForEach(locations, id: \.self) { location in
                        Section {
                            ForEach(medicines(in: location)) { medicine in
                                NavigationLink {
                                    AppMedicineDetailView(medicine: medicine)
                                } label: {
                                    AppMedicineRow(medicine: medicine)
                                }
                            }
                        } header: {
                            Text(location)
                        }
                    }
                }
            }
            .navigationTitle("存放位置")
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }
}

struct AppLocationEmptyView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.slash")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("还没有存放位置")
                .font(.headline)
            Text("添加药品并填写位置后，这里会按位置分组展示。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .listRowBackground(Color.clear)
    }
}

struct AppSummaryView: View {
    @EnvironmentObject var store: AppStore

    private var totalCount: Int {
        store.medicines.count
    }

    private var expiredCount: Int {
        store.medicines.filter { $0.isExpired }.count
    }

    private var expiringCount: Int {
        store.medicines.filter { !$0.isExpired && $0.daysUntilExpiry <= 30 }.count
    }

    private var uniqueLocations: [String] {
        Array(Set(store.medicines.map(\.location))).sorted()
    }

    private var nearestExpiry: AppMedicine? {
        store.medicines
            .filter { !$0.isExpired }
            .min(by: { $0.daysUntilExpiry < $1.daysUntilExpiry })
    }

    private var recentlyAdded: [AppMedicine] {
        Array(store.medicines.sorted { $0.dateAdded > $1.dateAdded }.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if store.medicines.isEmpty {
                        AppSummaryEmptyView()
                    } else {
                        HStack(spacing: 12) {
                            AppStatCard(title: "总药品", value: "\(totalCount)", icon: "pills", color: .accentColor)
                            AppStatCard(title: "已过期", value: "\(expiredCount)", icon: "exclamationmark.triangle", color: .red)
                        }
                        HStack(spacing: 12) {
                            AppStatCard(title: "30 天内到期", value: "\(expiringCount)", icon: "clock.badge.exclamationmark", color: .orange)
                            AppStatCard(title: "存放位置", value: "\(uniqueLocations.count)", icon: "location.fill", color: .blue)
                        }

                        if let nearestExpiry = nearestExpiry {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("最近到期")
                                    .font(.headline)
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(nearestExpiry.name)
                                            .font(.subheadline.bold())
                                        Text("\(nearestExpiry.location) · \(nearestExpiry.specification)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(nearestExpiry.daysUntilExpiry <= 30 ? "\(nearestExpiry.daysUntilExpiry) 天后" : AppDateText.expiry(nearestExpiry.expiryDate))
                                        .font(.caption.bold())
                                        .foregroundStyle(nearestExpiry.daysUntilExpiry <= 30 ? .orange : .secondary)
                                }
                                .padding()
                                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("最近添加")
                                .font(.headline)
                            ForEach(recentlyAdded) { medicine in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(medicine.name)
                                            .font(.subheadline.bold())
                                        Text(AppDateText.added(medicine.dateAdded))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(medicine.location)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("药箱总览")
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }
}

struct AppStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct AppSummaryEmptyView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("暂无统计数据")
                .font(.headline)
            Text("添加药品后，这里会展示效期和位置概览。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

struct AppMedicineDetailView: View {
    @EnvironmentObject var store: AppStore
    let medicine: AppMedicine
    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss

    private var currentMedicine: AppMedicine {
        store.medicines.first(where: { $0.id == medicine.id }) ?? medicine
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(currentMedicine.name)
                            .font(.title2.bold())
                        Text(currentMedicine.specification.isEmpty ? "未填写规格" : currentMedicine.specification)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        toggleFavorite()
                    } label: {
                        Image(systemName: currentMedicine.isFavorite ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundStyle(currentMedicine.isFavorite ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 14) {
                    AppDetailRow(label: "数量", value: "\(currentMedicine.quantity) \(currentMedicine.unit)")
                    AppDetailRow(label: "有效期至", value: AppDateText.expiry(currentMedicine.expiryDate))
                    AppDetailRow(label: "状态", value: statusText)
                    AppDetailRow(label: "存放位置", value: currentMedicine.location)
                    AppDetailRow(label: "添加时间", value: AppDateText.added(currentMedicine.dateAdded))
                    if !currentMedicine.notes.isEmpty {
                        AppDetailRow(label: "备注", value: currentMedicine.notes)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))

                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    Label("删除药品", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle(currentMedicine.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("编辑") {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AppMedicineEditView(mode: .edit(currentMedicine))
        }
        .confirmationDialog("确定删除这个药品吗？", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                delete()
            }
            Button("取消", role: .cancel) {}
        }
    }

    private var statusText: String {
        if currentMedicine.isExpired {
            let days = abs(currentMedicine.daysUntilExpiry)
            return days == 0 ? "今天过期" : "已过期 \(days) 天"
        }
        if currentMedicine.daysUntilExpiry <= 30 {
            return "\(currentMedicine.daysUntilExpiry) 天后到期"
        }
        return "正常"
    }

    private func toggleFavorite() {
        if let index = store.medicines.firstIndex(where: { $0.id == currentMedicine.id }) {
            store.medicines[index].isFavorite.toggle()
            store.save()
        }
    }

    func delete() {
        withAnimation {
            store.medicines.removeAll { $0.id == currentMedicine.id }
            store.save()
        }
        dismiss()
    }
}

struct AppDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

struct AppMedicineEditView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let mode: AppMedicineEditMode

    @State private var name = ""
    @State private var specification = ""
    @State private var quantity = 1
    @State private var unit = "盒"
    @State private var expiryDate = Calendar.current.date(byAdding: .month, value: 12, to: Date()) ?? Date()
    @State private var location = "家庭药箱"
    @State private var notes = ""
    @State private var isFavorite = false

    private var isEditing: Bool {
        if case .edit = mode {
            return true
        }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("药品名称，例如：布洛芬缓释胶囊", text: $name)
                    TextField("规格，例如：0.3g×20粒", text: $specification)
                }

                Section("数量与单位") {
                    Stepper(value: $quantity, in: 1...999) {
                        HStack {
                            Text("数量")
                            Spacer()
                            Text("\(quantity)")
                        }
                    }
                    TextField("单位，例如：盒、瓶、袋", text: $unit)
                }

                Section("有效期") {
                    DatePicker("有效期至", selection: $expiryDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                }

                Section("存放位置") {
                    TextField("例如：客厅药箱、冰箱冷藏层", text: $location)
                    if !store.locations.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(store.locations, id: \.self) { loc in
                                    Button {
                                        location = loc
                                    } label: {
                                        Text(loc)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(location == loc ? Color.primary.opacity(0.12) : Color.secondary.opacity(0.08), in: Capsule())
                                            .foregroundStyle(location == loc ? Color.primary : Color.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                Section("备注") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                Section {
                    Toggle("收藏该药品", isOn: $isFavorite)
                }
            }
            .navigationTitle(isEditing ? "编辑药品" : "添加药品")
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
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if case .edit(let medicine) = mode {
                    name = medicine.name
                    specification = medicine.specification
                    quantity = medicine.quantity
                    unit = medicine.unit
                    expiryDate = medicine.expiryDate
                    location = medicine.location
                    notes = medicine.notes
                    isFavorite = medicine.isFavorite
                }
            }
        }
    }

    func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSpecification = specification.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        switch mode {
        case .add:
            let medicine = AppMedicine(
                id: UUID(),
                name: trimmedName,
                specification: trimmedSpecification,
                quantity: quantity,
                unit: trimmedUnit.isEmpty ? "盒" : trimmedUnit,
                expiryDate: expiryDate,
                location: trimmedLocation.isEmpty ? "未指定位置" : trimmedLocation,
                dateAdded: Date(),
                notes: notes,
                isFavorite: isFavorite
            )
            store.medicines.append(medicine)
            if !store.locations.contains(medicine.location) {
                store.locations.append(medicine.location)
            }
            store.save()
        case .edit(let original):
            if let index = store.medicines.firstIndex(where: { $0.id == original.id }) {
                let updated = AppMedicine(
                    id: original.id,
                    name: trimmedName,
                    specification: trimmedSpecification,
                    quantity: quantity,
                    unit: trimmedUnit.isEmpty ? "盒" : trimmedUnit,
                    expiryDate: expiryDate,
                    location: trimmedLocation.isEmpty ? "未指定位置" : trimmedLocation,
                    dateAdded: original.dateAdded,
                    notes: notes,
                    isFavorite: isFavorite
                )
                store.medicines[index] = updated
                if !store.locations.contains(updated.location) {
                    store.locations.append(updated.location)
                }
                store.save()
            }
        }
        dismiss()
    }
}