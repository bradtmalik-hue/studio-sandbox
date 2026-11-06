import SwiftUI
import Foundation
import Combine

enum AppFormatters {
    static let expiryDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()
    static let expiryShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()
}

struct AppMedicineRow: View {
    let item: AppMedicineItem

    var isExpired: Bool {
        item.expiryDate < Date()
    }
    var isExpiringSoon: Bool {
        !isExpired && item.expiryDate <= Date().addingTimeInterval(86400 * 30)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isExpired ? "exclamationmark.triangle.fill" : (isExpiringSoon ? "clock.badge.exclamationmark.fill" : "pills.fill"))
                .foregroundStyle(isExpired ? .red : (isExpiringSoon ? .orange : .secondary))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                Text(item.location)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("有效期至 \(AppFormatters.expiryDisplay.string(from: item.expiryDate))")
                    .font(.caption)
                    .foregroundStyle(isExpired ? .red : (isExpiringSoon ? .orange : .secondary))
            }
            Spacer()
            Text("\(item.quantity)盒")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AppMedicineListView: View {
    @EnvironmentObject var store: AppMedicineStore
    @State private var showingAddForm = false

    private var sortedItems: [AppMedicineItem] {
        store.items.sorted { $0.expiryDate < $1.expiryDate }
    }
    private var expiredItems: [AppMedicineItem] {
        sortedItems.filter { $0.expiryDate < Date() }
    }
    private var expiringSoonItems: [AppMedicineItem] {
        sortedItems.filter { $0.expiryDate >= Date() && $0.expiryDate <= Date().addingTimeInterval(86400 * 30) }
    }
    private var otherItems: [AppMedicineItem] {
        sortedItems.filter { $0.expiryDate > Date().addingTimeInterval(86400 * 30) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.items.isEmpty {
                    emptyState
                } else {
                    List {
                        if !expiredItems.isEmpty {
                            Section("已过期") {
                                ForEach(expiredItems) { item in
                                    NavigationLink {
                                        AppMedicineDetailView(itemID: item.id)
                                    } label: {
                                        AppMedicineRow(item: item)
                                    }
                                }
                            }
                        }
                        if !expiringSoonItems.isEmpty {
                            Section("30天内到期") {
                                ForEach(expiringSoonItems) { item in
                                    NavigationLink {
                                        AppMedicineDetailView(itemID: item.id)
                                    } label: {
                                        AppMedicineRow(item: item)
                                    }
                                }
                            }
                        }
                        if !otherItems.isEmpty {
                            Section("其他") {
                                ForEach(otherItems) { item in
                                    NavigationLink {
                                        AppMedicineDetailView(itemID: item.id)
                                    } label: {
                                        AppMedicineRow(item: item)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("家庭药箱")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddForm) {
                AppMedicineFormView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pills.circle")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("药箱空空如也")
                .font(.title3.weight(.semibold))
            Text("点击右上角 + 添加第一盒药\n记录保质期和存放位置")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AppMedicineDetailView: View {
    @EnvironmentObject var store: AppMedicineStore
    @Environment(\.dismiss) var dismiss
    let itemID: UUID
    @State private var showingEditForm = false
    @State private var showingDeleteConfirm = false

    var item: AppMedicineItem? {
        store.items.first { $0.id == itemID }
    }

    var body: some View {
        Group {
            if let item = item {
                List {
                    Section("药品信息") {
                        LabeledContent("名称", value: item.name)
                        LabeledContent("有效期至", value: AppFormatters.expiryDisplay.string(from: item.expiryDate))
                        LabeledContent("数量", value: "\(item.quantity)盒")
                    }
                    Section("存放位置") {
                        Text(item.location)
                    }
                    if !item.notes.isEmpty {
                        Section("备注") {
                            Text(item.notes)
                        }
                    }
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Text("删除这盒药")
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle(item.name)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("编辑") {
                            showingEditForm = true
                        }
                    }
                }
                .sheet(isPresented: $showingEditForm) {
                    AppMedicineFormView(item: item)
                }
                .alert("确认删除？", isPresented: $showingDeleteConfirm) {
                    Button("删除", role: .destructive) {
                        store.delete(item)
                        dismiss()
                    }
                    Button("取消", role: .cancel) {}
                } message: {
                    Text("删除后无法恢复")
                }
            } else {
                ContentUnavailableView("药品不存在", systemImage: "questionmark.circle")
            }
        }
    }
}

struct AppMedicineFormView: View {
    @EnvironmentObject var store: AppMedicineStore
    @Environment(\.dismiss) var dismiss
    let item: AppMedicineItem?

    @State private var name: String
    @State private var expiryDate: Date
    @State private var location: String
    @State private var quantity: Int
    @State private var notes: String

    init(item: AppMedicineItem? = nil) {
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _expiryDate = State(initialValue: item?.expiryDate ?? Date().addingTimeInterval(86400 * 365))
        _location = State(initialValue: item?.location ?? "")
        _quantity = State(initialValue: item?.quantity ?? 1)
        _notes = State(initialValue: item?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("药品名称") {
                    TextField("例如：阿莫西林胶囊", text: $name)
                }
                Section("有效期至") {
                    DatePicker("有效期至", selection: $expiryDate, displayedComponents: .date)
                }
                Section("存放位置") {
                    TextField("例如：卧室药箱第一层", text: $location)
                }
                Section("数量") {
                    Stepper("\(quantity) 盒", value: $quantity, in: 1...100)
                }
                Section("备注") {
                    TextField("可选", text: $notes)
                }
            }
            .navigationTitle(item == nil ? "添加药品" : "编辑药品")
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
                }
            }
        }
    }

    func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedLocation.isEmpty else { return }
        let newItem = AppMedicineItem(
            id: item?.id ?? UUID(),
            name: trimmedName,
            expiryDate: expiryDate,
            location: trimmedLocation,
            quantity: quantity,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        if item == nil {
            store.add(newItem)
        } else {
            store.update(newItem)
        }
        dismiss()
    }
}

struct AppExpiryReminderView: View {
    @EnvironmentObject var store: AppMedicineStore

    private var expiringItems: [AppMedicineItem] {
        store.items
            .filter { $0.expiryDate <= Date().addingTimeInterval(86400 * 30) }
            .sorted { $0.expiryDate < $1.expiryDate }
    }

    var body: some View {
        NavigationStack {
            Group {
                if expiringItems.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(expiringItems) { item in
                            NavigationLink {
                                AppMedicineDetailView(itemID: item.id)
                            } label: {
                                AppMedicineRow(item: item)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("临期提醒")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("没有临期药品")
                .font(.title3.weight(.semibold))
            Text("所有药品都在安全期内")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AppLocationView: View {
    @EnvironmentObject var store: AppMedicineStore

    private var groupedItems: [(key: String, value: [AppMedicineItem])] {
        Dictionary(grouping: store.items, by: { $0.location })
            .map { (key: $0.key, value: $0.value.sorted { $0.expiryDate < $1.expiryDate }) }
            .sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            Group {
                if groupedItems.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(groupedItems, id: \.key) { group in
                            Section(group.key) {
                                ForEach(group.value) { item in
                                    NavigationLink {
                                        AppMedicineDetailView(itemID: item.id)
                                    } label: {
                                        AppMedicineRow(item: item)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("存放位置")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("还没有存放位置")
                .font(.title3.weight(.semibold))
            Text("添加药品时填写存放位置\n这里会按位置分类显示")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}