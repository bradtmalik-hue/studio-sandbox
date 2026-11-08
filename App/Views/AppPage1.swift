import SwiftUI

private let AppPage1DateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M月d日"
    return formatter
}()

struct AppPage1View: View {
    @EnvironmentObject private var store: AppInventoryStore
    @State private var searchText = ""
    @State private var selectedCategory = "全部"

    var categories: [String] {
        var set = Set(store.items.map { $0.category })
        set.insert("全部")
        return ["全部"] + set.filter { $0 != "全部" }.sorted()
    }

    private var filteredItems: [AppPetSupplyItem] {
        store.items.filter { item in
            let matchesCategory = selectedCategory == "全部" || item.category == selectedCategory
            let query = searchText.trimmingCharacters(in: .whitespaces)
            let matchesSearch = query.isEmpty
                || item.name.localizedCaseInsensitiveContains(query)
                || item.category.localizedCaseInsensitiveContains(query)
                || item.notes.localizedCaseInsensitiveContains(query)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppPage1SummaryCard(
                    totalItemCount: store.totalItemCount,
                    totalQuantity: store.totalQuantity,
                    expiringSoonCount: store.expiringSoonCount
                )
                .padding(.horizontal)
                .padding(.top, 8)

                searchBar
                    .padding(.horizontal)
                    .padding(.top, 12)

                Picker("分类筛选", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 12)

                if store.items.isEmpty {
                    AppPage1EmptyState()
                } else if filteredItems.isEmpty {
                    ContentUnavailableView {
                        Label("没有匹配结果", systemImage: "magnifyingglass")
                    } description: {
                        Text("换一个关键词或分类试试")
                    }
                } else {
                    List {
                        ForEach(filteredItems, id: \.id) { item in
                            NavigationLink {
                                AppPage1EditView(item: item)
                            } label: {
                                AppPage1Row(item: item)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    delete(item)
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
            .navigationTitle("库存列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AppPage1EditView(item: nil)
                    } label: {
                        Label("添加", systemImage: "plus")
                    }
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("搜索名称、分类或备注", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    func delete(_ item: AppPetSupplyItem) {
        guard let index = store.items.firstIndex(where: { $0.id == item.id }) else { return }
        store.items.remove(at: index)
        store.save()
    }
}

struct AppPage1SummaryCard: View {
    let totalItemCount: Int
    let totalQuantity: Double
    let expiringSoonCount: Int

    var body: some View {
        HStack(spacing: 12) {
            AppPage1SummaryItem(
                icon: "pawprint.fill",
                value: "\(totalItemCount)",
                unit: "件",
                label: "总件数",
                tint: Color.blue
            )
            AppPage1SummaryItem(
                icon: "sum",
                value: String(format: "%.1f", totalQuantity),
                unit: "",
                label: "总数量",
                tint: Color.teal
            )
            AppPage1SummaryItem(
                icon: "exclamationmark.triangle.fill",
                value: "\(expiringSoonCount)",
                unit: "件",
                label: "快过期",
                tint: Color.orange
            )
        }
    }
}

struct AppPage1SummaryItem: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(tint)
                Spacer()
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.weight(.bold))
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct AppPage1Row: View {
    let item: AppPetSupplyItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pawprint.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 36, height: 36)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                    if isExpiringSoon {
                        Text("快过期")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Text("\(item.category) · \(String(format: "%.1f", item.quantity)) \(item.unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("过期：\(AppPage1DateFormatter.string(from: item.expirationDate))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.tertiary)
        }
        .padding(.vertical, 6)
    }

    private var isExpiringSoon: Bool {
        item.expirationDate < Date().addingTimeInterval(30 * 24 * 60 * 60)
    }
}

struct AppPage1EmptyState: View {
    var body: some View {
        ContentUnavailableView {
            Label("暂无宠物用品", systemImage: "pawprint")
        } description: {
            Text("点击下方按钮添加第一条库存记录")
        } actions: {
            NavigationLink {
                AppPage1EditView(item: nil)
            } label: {
                Label("添加第一条", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct AppPage1EditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppInventoryStore

    let item: AppPetSupplyItem?

    @State private var name: String
    @State private var quantityText: String
    @State private var unit: String
    @State private var expirationDate: Date
    @State private var category: String
    @State private var notes: String

    init(item: AppPetSupplyItem?) {
        self.item = item
        let initialName = item?.name ?? ""
        _name = State(initialValue: initialName)
        let initialQuantity = item.map { String(format: "%.2f", $0.quantity) } ?? "1"
        _quantityText = State(initialValue: initialQuantity)
        _unit = State(initialValue: item?.unit ?? "件")
        _expirationDate = State(initialValue: item?.expirationDate ?? Date())
        _category = State(initialValue: item?.category ?? "未分类")
        _notes = State(initialValue: item?.notes ?? "")
    }

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("名称", text: $name)
                    .textInputAutocapitalization(.never)

                TextField("数量", text: $quantityText)
                    .keyboardType(.decimalPad)

                if quantityValue <= 0 {
                    Text("数量必须大于 0")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                TextField("单位", text: $unit)
            }

            Section("分类与过期") {
                Picker("分类", selection: $category) {
                    ForEach(categoryOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }

                DatePicker("过期日期", selection: $expirationDate, displayedComponents: .date)
            }

            Section("备注") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle(item == nil ? "新增物品" : "编辑物品")
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
                .disabled(saveDisabled)
            }
        }
    }

    private var quantityValue: Double {
        Double(quantityText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var saveDisabled: Bool {
        name.trimmingCharacters(in: .whitespaces).isEmpty
            || unit.trimmingCharacters(in: .whitespaces).isEmpty
            || category.trimmingCharacters(in: .whitespaces).isEmpty
            || quantityValue <= 0
    }

    private var categoryOptions: [String] {
        var options = Set(store.items.map { $0.category })
        let currentCategory = category.trimmingCharacters(in: .whitespaces)
        if !currentCategory.isEmpty {
            options.insert(currentCategory)
        }
        if options.isEmpty {
            options.insert("未分类")
        }
        return options.sorted()
    }

    func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespaces)
        let trimmedCategory = category.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let newItem = AppPetSupplyItem(
            id: item?.id ?? UUID(),
            name: trimmedName,
            quantity: quantityValue,
            unit: trimmedUnit,
            expirationDate: expirationDate,
            category: trimmedCategory,
            notes: trimmedNotes
        )

        if let item = item, let index = store.items.firstIndex(where: { $0.id == item.id }) {
            store.items[index] = newItem
        } else {
            store.items.append(newItem)
        }

        store.save()
        dismiss()
    }
}