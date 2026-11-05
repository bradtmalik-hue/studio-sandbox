import SwiftUI
import Foundation

// MARK: - 主页视图
struct AppHomeView: View {
    @EnvironmentObject var store: AppMedicineStore
    @State private var searchText = ""

    var filteredItems: [AppMedicineItem] {
        if searchText.isEmpty {
            return store.items
        }
        return store.items.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.storageSpot.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.items.isEmpty {
                    ContentUnavailableView(
                        "还没有药品",
                        systemImage: "pills.fill",
                        description: Text("点击右上角添加第一盒药，记录有效期和存放位置。")
                    )
                } else {
                    List(filteredItems) { item in
                        NavigationLink(destination: AppMedicineDetailView(item: item)) {
                            AppMedicineRowView(item: item)
                        }
                    }
                    .searchable(text: $searchText, prompt: "搜索药品名称或位置")
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("家庭药箱")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(destination: AppAddMedicineView()) {
                        Label("添加", systemImage: "plus")
                    }
                }
            }
        }
    }
}

// MARK: - 药品行视图
struct AppMedicineRowView: View {
    let item: AppMedicineItem

    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: item.expiryDate).day ?? 0
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                Text(item.storageSpot)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.expiryDate, format: .dateTime.day().month().year())
                    .font(.caption)
                if item.expiryDate < Date() {
                    Label("已过期", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if daysRemaining <= 30 {
                    Text("剩 \(daysRemaining) 天")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Label("有效", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 添加药品视图
struct AppAddMedicineView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppMedicineStore

    @State private var name = ""
    @State private var storageSpot = "家庭药箱"
    @State private var expiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()

    var body: some View {
        Form {
            Section("药品信息") {
                TextField("药品名称", text: $name)
                TextField("存放位置", text: $storageSpot)
                DatePicker("有效期至", selection: $expiryDate, displayedComponents: .date)
            }
            Section {
                Button("保存") {
                    let newItem = AppMedicineItem(name: name, storageSpot: storageSpot, expiryDate: expiryDate)
                    store.add(newItem)
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("添加药品")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 药品详情视图
struct AppMedicineDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppMedicineStore
    let item: AppMedicineItem

    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: item.expiryDate).day ?? 0
    }

    var body: some View {
        Form {
            Section("药品信息") {
                LabeledContent("名称", value: item.name)
                LabeledContent("存放位置", value: item.storageSpot)
                LabeledContent("有效期至") {
                    Text(item.expiryDate, format: .dateTime.day().month().year())
                }
            }

            if item.expiryDate < Date() {
                Section {
                    Label("该药品已过期，请尽快处理。", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            } else if daysRemaining <= 30 {
                Section {
                    Label("剩余 \(daysRemaining) 天过期", systemImage: "clock.badge.exclamationmark")
                        .foregroundStyle(.orange)
                }
            }

            Section {
                Button(role: .destructive) {
                    store.delete(item)
                    dismiss()
                } label: {
                    Text("删除药品")
                }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 有效期提醒视图
struct AppExpiryView: View {
    @EnvironmentObject var store: AppMedicineStore

    var expiredItems: [AppMedicineItem] {
        store.items.filter { $0.expiryDate < Date() }
    }

    var expiringSoonItems: [AppMedicineItem] {
        store.items.filter { !($0.expiryDate < Date()) && daysUntilExpiry($0) <= 30 }
    }

    private var validItems: [AppMedicineItem] {
        store.items.filter { !($0.expiryDate < Date()) && daysUntilExpiry($0) > 30 }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.items.isEmpty {
                    ContentUnavailableView(
                        "暂无药品",
                        systemImage: "pills",
                        description: Text("添加药品后，这里会显示有效期提醒。")
                    )
                } else {
                    List {
                        if !expiredItems.isEmpty {
                            Section("已过期") {
                                ForEach(expiredItems) { item in
                                    AppMedicineRowView(item: item)
                                }
                            }
                        }
                        if !expiringSoonItems.isEmpty {
                            Section("即将过期（30 天内）") {
                                ForEach(expiringSoonItems) { item in
                                    AppMedicineRowView(item: item)
                                }
                            }
                        }
                        if !validItems.isEmpty {
                            Section("有效期内") {
                                ForEach(validItems) { item in
                                    AppMedicineRowView(item: item)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("有效期提醒")
        }
    }

    private func daysUntilExpiry(_ item: AppMedicineItem) -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: item.expiryDate).day ?? 0
    }
}

// MARK: - 存放位置视图
struct AppStorageView: View {
    @EnvironmentObject var store: AppMedicineStore

    private var groupedBySpot: [(spot: String, items: [AppMedicineItem])] {
        let grouped = Dictionary(grouping: store.items, by: { $0.storageSpot })
        return grouped.map { (spot: $0.key, items: $0.value) }
            .sorted { $0.spot < $1.spot }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.items.isEmpty {
                    ContentUnavailableView(
                        "暂无存放记录",
                        systemImage: "cabinet",
                        description: Text("添加药品后，这里会按存放位置分类显示。")
                    )
                } else {
                    List {
                        ForEach(groupedBySpot, id: \.spot) { group in
                            Section(group.spot) {
                                ForEach(group.items) { item in
                                    Text(item.name)
                                        .font(.body)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("存放位置")
        }
    }
}