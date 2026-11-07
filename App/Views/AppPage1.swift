import SwiftUI
import Combine

struct AppPage1View: View {
    @EnvironmentObject private var store: AppStore
    @State private var searchText = ""
    @State private var filterCategory = "全部"
    @State private var showingAddSheet = false
    @State private var editingExpense: AppExpense? = nil

    private var allCategories: [String] {
        var cats = Set(store.expenses.map { $0.category })
        cats.insert("全部")
        return Array(cats).sorted()
    }

    private var filteredExpenses: [AppExpense] {
        var result = store.expenses
        if filterCategory != "全部" {
            result = result.filter { $0.category == filterCategory }
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.title.lowercased().contains(query) || $0.payer.lowercased().contains(query)
            }
        }
        return result.sorted { $0.date > $1.date }
    }

    private var latestExpenseDate: Date? {
        store.expenses.map(\.date).max()
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage1SummaryCard(
                        totalCount: store.expenses.count,
                        totalAmount: store.totalAmount,
                        latestDate: latestExpenseDate,
                        average: store.averagePerExpense
                    )
                }

                Section {
                    AppPage1SearchFilter(categories: allCategories)
                }

                Section {
                    if store.expenses.isEmpty {
                        AppPage1EmptyState {
                            showingAddSheet = true
                        }
                    } else if filteredExpenses.isEmpty {
                        ContentUnavailableView {
                            Label("没有匹配结果", systemImage: "magnifyingglass")
                        } description: {
                            Text("换个关键词或分类试试")
                        }
                    } else {
                        ForEach(filteredExpenses) { expense in
                            Button {
                                editingExpense = expense
                            } label: {
                                AppPage1Row(expense: expense)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    delete(expense)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("记一笔")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingExpense = nil
                        showingAddSheet = true
                    } label: {
                        Label("添加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AppPage1EditView(expense: nil)
            }
            .sheet(item: $editingExpense) { expense in
                AppPage1EditView(expense: expense)
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }

    func delete(_ expense: AppExpense) {
        store.expenses.removeAll { $0.id == expense.id }
        store.save()
    }
}

struct AppPage1SummaryCard: View {
    let totalCount: Int
    let totalAmount: Double
    let latestDate: Date?
    let average: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("共 \(totalCount) 笔")
                    .font(.headline)
                Spacer()
                Text(amountText(totalAmount))
                    .font(.title2.bold())
            }
            HStack {
                if let latestDate = latestDate {
                    Label("最近: \(dateText(latestDate))", systemImage: "clock")
                } else {
                    Label("最近: 暂无", systemImage: "clock")
                }
                Spacer()
                Label("平均 \(amountText(average))", systemImage: "chart.bar")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func amountText(_ value: Double) -> String {
        String(format: "¥%.2f", value)
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

struct AppPage1SearchFilter: View {
    @Binding var searchText: String
    @Binding var filterCategory: String
    let categories: [String]

    var body: some View {
        VStack(spacing: 8) {
            TextField("搜索标题或付款人", text: $searchText)
                .textFieldStyle(.roundedBorder)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            filterCategory = category
                        } label: {
                            Text(category)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(filterCategory == category ? Color.accentColor : Color.secondary.opacity(0.2))
                                .foregroundStyle(filterCategory == category ? Color.white : Color.primary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct AppPage1EmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("还没有记录", systemImage: "party.popper")
        } description: {
            Text("点击右上角 + 或下方按钮，记下第一笔聚会花费")
        } actions: {
            Button("添加第一条", action: onAdd)
        }
    }
}

struct AppPage1Row: View {
    let expense: AppExpense

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.headline)
                Text("\(expense.payer) 支付 · \(expense.participantCount)人")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(amountText(expense.amount))
                    .font(.headline)
                Text(dateText(expense.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func amountText(_ value: Double) -> String {
        String(format: "¥%.2f", value)
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

struct AppPage1EditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    let expense: AppExpense?

    @State private var title: String
    @State private var amount: Double
    @State private var payer: String
    @State private var date: Date
    @State private var participantCount: Int
    @State private var note: String
    @State private var category: String
    @State private var showValidationAlert = false

    private let categories = ["餐饮", "交通", "娱乐", "住宿", "其他"]

    init(expense: AppExpense?) {
        self.expense = expense
        _title = State(initialValue: expense?.title ?? "")
        _amount = State(initialValue: expense?.amount ?? 0)
        _payer = State(initialValue: expense?.payer ?? "")
        _date = State(initialValue: expense?.date ?? Date())
        _participantCount = State(initialValue: expense?.participantCount ?? 2)
        _note = State(initialValue: expense?.note ?? "")
        _category = State(initialValue: expense?.category ?? "餐饮")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("标题（如：火锅聚餐）", text: $title)
                    TextField("付款人", text: $payer)
                    Picker("分类", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                    DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                Section("金额与人数") {
                    HStack {
                        Text("金额")
                        Spacer()
                        TextField("0.00", value: $amount, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    Stepper("参与人数: \(participantCount)", value: $participantCount, in: 2...99)
                }
                Section("备注") {
                    TextField("备注（可选）", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(expense == nil ? "记一笔" : "编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if isValid {
                            save()
                            dismiss()
                        } else {
                            showValidationAlert = true
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .alert("请检查输入", isPresented: $showValidationAlert) {
                Button("好", role: .cancel) { }
            } message: {
                Text("标题和付款人不能为空，金额需大于0，参与人数至少2人。")
            }
        }
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !payer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        amount > 0 &&
        participantCount >= 2
    }

    func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPayer = payer.trimmingCharacters(in: .whitespacesAndNewlines)
        let newExpense = AppExpense(
            id: expense?.id ?? UUID(),
            title: trimmedTitle,
            amount: amount,
            payer: trimmedPayer,
            date: date,
            participantCount: participantCount,
            participants: [],
            note: note,
            category: category
        )
        if let existing = expense, let index = store.expenses.firstIndex(where: { $0.id == existing.id }) {
            store.expenses[index] = newExpense
        } else {
            store.expenses.append(newExpense)
        }
        store.save()
    }
}