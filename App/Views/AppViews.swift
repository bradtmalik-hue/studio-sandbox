import SwiftUI

// MARK: - 随手记列表页

struct AppRecordListView: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText: String = ""
    @State private var showingAddSheet = false

    private var sortedRecords: [AppRecord] {
        store.records.sorted { $0.date > $1.date }
    }

    private var filteredRecords: [AppRecord] {
        if searchText.isEmpty {
            return sortedRecords
        }
        return sortedRecords.filter { record in
            record.note.localizedCaseInsensitiveContains(searchText) ||
            record.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredRecords.isEmpty {
                    AppRecordEmptyStateView()
                } else {
                    List {
                        ForEach(filteredRecords) { record in
                            AppRecordRow(record: record)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        store.delete(record)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "搜索备注或分类")
            .navigationTitle("随手记")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("记一笔")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AppAddRecordView()
            }
        }
    }
}

// MARK: - 空状态

struct AppRecordEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("还没有记录")
                .font(.title2)
                .fontWeight(.semibold)
            Text("点击右上角 + 随手记一笔")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.05))
    }
}

// MARK: - 记录行

struct AppRecordRow: View {
    let record: AppRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(Color.gray.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(record.note.isEmpty ? "无备注" : record.note)
                    .font(.body)
                    .foregroundStyle(.primary)
                HStack {
                    Text(record.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(record.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(String(format: "¥%.2f", record.amount))
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 添加记录

struct AppAddRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore

    @State private var category: AppRecordCategory = AppRecordCategory.allCases.first!
    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var date = Date()
    @State private var showValidationError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("分类") {
                    Picker("分类", selection: $category) {
                        ForEach(AppRecordCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("金额") {
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                }

                Section("备注") {
                    TextField("例如：午餐、打车、买书", text: $note)
                }

                Section("日期") {
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("记一笔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveRecord() }
                        .disabled(amountText.isEmpty || Double(amountText) == nil)
                }
            }
            .alert("请输入有效金额", isPresented: $showValidationError) {
                Button("好", role: .cancel) { }
            }
        }
    }

    private func saveRecord() {
        guard let amount = Double(amountText), amount > 0 else {
            showValidationError = true
            return
        }
        let record = AppRecord(
            id: UUID(),
            category: category,
            amount: amount,
            note: note,
            date: date
        )
        store.add(record)
        dismiss()
    }
}

// MARK: - 统计页

struct AppStatsView: View {
    @EnvironmentObject var store: AppStore

    var total: Double {
        store.records.reduce(0) { $0 + $1.amount }
    }

    private var average: Double {
        store.records.isEmpty ? 0 : total / Double(store.records.count)
    }

    private var categoriesWithRecords: [AppRecordCategory] {
        Array(Set(store.records.map { $0.category }))
    }

    private var maxCategoryAmount: Double {
        categoriesWithRecords
            .map { category in
                store.records.filter { $0.category == category }.reduce(0) { $0 + $1.amount }
            }
            .max() ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text("总支出")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(String(format: "¥%.2f", total))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("共 \(store.records.count) 笔 · 平均 ¥\(String(format: "%.2f", average))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    if store.records.isEmpty {
                        AppStatsEmptyStateView()
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("分类占比")
                                .font(.headline)
                            ForEach(categoriesWithRecords, id: \.self) { category in
                                let amount = store.records.filter { $0.category == category }.reduce(0) { $0 + $1.amount }
                                AppCategoryStatRow(category: category, amount: amount, maxAmount: maxCategoryAmount)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .background(Color.gray.opacity(0.05))
            .navigationTitle("统计")
        }
    }
}

struct AppStatsEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("暂无统计数据")
                .font(.title3)
                .fontWeight(.semibold)
            Text("记几笔后这里会出现分类统计")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct AppCategoryStatRow: View {
    let category: AppRecordCategory
    let amount: Double
    let maxAmount: Double

    private var progress: Double {
        maxAmount > 0 ? amount / maxAmount : 0
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(category.rawValue, systemImage: "circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(String(format: "¥%.2f", amount))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.25))
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)
        }
    }
}