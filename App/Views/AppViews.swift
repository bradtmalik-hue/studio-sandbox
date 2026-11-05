import SwiftUI
import Combine

// MARK: - 通用组件

struct AppEmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

struct AppMedicineRow: View {
    let item: AppMedicineItem

    private var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: item.expiryDate)).day ?? 0
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                HStack(spacing: 6) {
                    Text(item.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Capsule())
                    Text(item.storageSpot.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.expiryDate, format: .dateTime.year().month().day())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if daysUntilExpiry < 0 {
                    Text("已过期")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if daysUntilExpiry <= 30 {
                    Text("\(daysUntilExpiry) 天后到期")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text("\(daysUntilExpiry) 天后到期")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 仪表盘

struct AppMedicineDashboardView: View {
    @EnvironmentObject var store: AppMedicineStore
    @State private var showingAdd = false

    private var totalCount: Int {
        store.items.count
    }

    var expiringSoonCount: Int {
        store.items.filter { item in
            let days = Calendar.current.dateComponents([.day], from: Date(), to: item.expiryDate).day ?? 0
            return days >= 0 && days <= 60
        }.count
    }

    private var locationCount: Int {
        Set(store.items.map { $0.storageSpot.rawValue }).count
    }

    private var sortedExpiringSoon: [AppMedicineItem] {
        store.items
            .filter { item in
                let days = Calendar.current.dateComponents([.day], from: Date(), to: item.expiryDate).day ?? 0
                return days >= 0 && days <= 60
            }
            .sorted { $0.expiryDate < $1.expiryDate }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 16) {
                        DashboardStatCard(title: "药品总数", value: "\(totalCount)", icon: "pills.fill", tint: .gray)
                        DashboardStatCard(title: "60天内到期", value: "\(expiringSoonCount)", icon: "clock.fill", tint: .orange)
                        DashboardStatCard(title: "存放位置", value: "\(locationCount)", icon: "location.fill", tint: .blue)
                    }
                    .padding(.horizontal)

                    if sortedExpiringSoon.isEmpty {
                        VStack {
                            AppEmptyStateView(
                                icon: "checkmark.circle",
                                title: "暂无临期药品",
                                message: "点击右上角 + 添加药品，系统会自动提醒临期。"
                            )
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("即将到期")
                                .font(.title3.bold())
                                .padding(.horizontal)
                            ForEach(sortedExpiringSoon) { item in
                                NavigationLink {
                                    AppMedicineDetailView(item: item)
                                } label: {
                                    AppMedicineRow(item: item)
                                        .padding(.horizontal)
                                        .padding(.vertical, 6)
                                        .background(Color.gray.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if store.items.isEmpty {
                        AppEmptyStateView(
                            icon: "shippingbox",
                            title: "药箱还是空的",
                            message: "添加第一种药品，记录有效期和存放位置，避免遗忘。"
                        )
                    }
                }
                .padding(.vertical)
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
                AppAddMedicineView()
            }
        }
    }
}

struct DashboardStatCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                Spacer()
                Text(value)
                    .font(.title2.bold())
            }
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 药品列表

struct AppMedicineListView: View {
    @EnvironmentObject var store: AppMedicineStore
    @State private var searchText = ""
    @State private var selectedCategory: AppMedicineCategory?

    private var filteredItems: [AppMedicineItem] {
        var result = store.items
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return result.sorted { $0.expiryDate < $1.expiryDate }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.items.isEmpty {
                    AppEmptyStateView(
                        icon: "shippingbox",
                        title: "药箱是空的",
                        message: "点击右上角 + 添加药品，开始管理你的家庭药箱。"
                    )
                } else {
                    List {
                        Picker("分类筛选", selection: $selectedCategory) {
                            Text("全部分类").tag(AppMedicineCategory?.none)
                            ForEach(AppMedicineCategory.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(Optional(category))
                            }
                        }
                        .pickerStyle(.menu)

                        ForEach(filteredItems) { item in
                            NavigationLink {
                                AppMedicineDetailView(item: item)
                            } label: {
                                AppMedicineRow(item: item)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .searchable(text: $searchText, prompt: "搜索药品名称")
                }
            }
            .navigationTitle("药品列表")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // 触发 sheet
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AppAddMedicineView()
            }
        }
    }

    @State private var showingAdd = false

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = filteredItems[index]
            store.delete(item)
        }
    }
}

// MARK: - 临期药品

struct AppExpiringSoonView: View {
    @EnvironmentObject var store: AppMedicineStore

    private var expiringItems: [AppMedicineItem] {
        store.items
            .filter { item in
                let days = Calendar.current.dateComponents([.day], from: Date(), to: item.expiryDate).day ?? 0
                return days >= 0 && days <= 60
            }
            .sorted { $0.expiryDate < $1.expiryDate }
    }

    var body: some View {
        NavigationStack {
            Group {
                if expiringItems.isEmpty {
                    AppEmptyStateView(
                        icon: "clock.badge.checkmark",
                        title: "没有临期药品",
                        message: "所有药品都在安全有效期内。"
                    )
                } else {
                    List {
                        ForEach(expiringItems) { item in
                            NavigationLink {
                                AppMedicineDetailView(item: item)
                            } label: {
                                AppMedicineRow(item: item)
                            }
                        }
                    }
                }
            }
            .navigationTitle("临期提醒")
        }
    }
}

// MARK: - 存放位置

struct AppStorageLocationView: View {
    @EnvironmentObject var store: AppMedicineStore

    private var locations: [AppStorageLocation] {
        AppStorageLocation.allCases
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.items.isEmpty {
                    AppEmptyStateView(
                        icon: "location.slash",
                        title: "暂无存放位置",
                        message: "添加药品后，这里会按存放位置分组显示。"
                    )
                } else {
                    List {
                        ForEach(locations, id: \.self) { location in
                            let items = store.items.filter { $0.storageSpot == location }
                            if !items.isEmpty {
                                Section {
                                    ForEach(items) { item in
                                        NavigationLink {
                                            AppMedicineDetailView(item: item)
                                        } label: {
                                            AppMedicineRow(item: item)
                                        }
                                    }
                                } header: {
                                    Text(location.rawValue)
                                        .font(.headline)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("存放位置")
        }
    }
}

// MARK: - 添加药品

struct AppAddMedicineView: View {
    @EnvironmentObject var store: AppMedicineStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedCategory: AppMedicineCategory = .other
    @State private var selectedStorageSpot: AppStorageLocation = .medicineCabinet
    @State private var expiryDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var quantity = 1

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("药品名称", text: $name)
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(AppMedicineCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    Stepper("数量：\(quantity)", value: $quantity, in: 1...999)
                }

                Section("存放与有效期") {
                    Picker("存放位置", selection: $selectedStorageSpot) {
                        ForEach(AppStorageLocation.allCases, id: \.self) { location in
                            Text(location.rawValue).tag(location)
                        }
                    }
                    DatePicker(
                        "有效期至",
                        selection: $expiryDate,
                        displayedComponents: .date
                    )
                }

                Section {
                    Button("保存") {
                        let newItem = AppMedicineItem(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            category: selectedCategory,
                            storageSpot: selectedStorageSpot,
                            expiryDate: expiryDate,
                            quantity: quantity
                        )
                        if !newItem.name.isEmpty {
                            store.add(newItem)
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("添加药品")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 药品详情

struct AppMedicineDetailView: View {
    @EnvironmentObject var store: AppMedicineStore
    @Environment(\.dismiss) private var dismiss

    let item: AppMedicineItem
    @State private var showingDeleteConfirmation = false

    private var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: item.expiryDate)).day ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name)
                        .font(.largeTitle.bold())
                    HStack {
                        Text(item.category.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Capsule())
                        Text(item.storageSpot.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("数量：\(item.quantity)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                HStack {
                    Label("有效期至", systemImage: "calendar")
                        .font(.headline)
                    Spacer()
                    Text(item.expiryDate, format: .dateTime.year().month().day())
                        .font(.body)
                }
                if daysUntilExpiry < 0 {
                    Label("已过期", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                } else {
                    Label("\(daysUntilExpiry) 天后到期", systemImage: "clock")
                        .foregroundStyle(daysUntilExpiry <= 30 ? .orange : .secondary)
                }

                Divider()

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("删除此药品", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()
        }
        .navigationTitle("药品详情")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("确定删除吗？", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                store.delete(item)
                dismiss()
            }
            Button("取消", role: .cancel) { }
        }
    }
}