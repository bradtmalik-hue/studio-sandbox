import SwiftUI
import Foundation

private let AppPage1DateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M月d日 HH:mm"
    return formatter
}()

private func AppPage1AmountString(_ amount: Double, currencyCode: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currencyCode
    formatter.locale = Locale(identifier: "zh_CN")
    return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
}

struct AppPage1View: View {
    @EnvironmentObject private var store: AppStore

    @State private var title = ""
    @State private var amountString = ""
    @State private var paidBy = ""
    @State private var participantCount = 2
    @State private var payerIncluded = true
    @State private var date = Date()
    @State private var note = ""
    @State private var searchText = ""
    @State private var payerFilter = 0
    @State private var didLoadDefaults = false
    @State private var showSaveAlert = false

    var amount: Double {
        Double(amountString) ?? 0
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        amount > 0 &&
        !paidBy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        participantCount > 0
    }

    private var filteredExpenses: [AppExpense] {
        let sorted = store.expenses.sorted { $0.date > $1.date }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        return sorted.filter { expense in
            if !query.isEmpty {
                let matchesTitle = expense.title.localizedCaseInsensitiveContains(query)
                let matchesPayer = expense.paidBy.localizedCaseInsensitiveContains(query)
                if !matchesTitle && !matchesPayer {
                    return false
                }
            }

            switch payerFilter {
            case 1:
                return expense.paidBy == store.settings.defaultPayer
            case 2:
                return expense.paidBy != store.settings.defaultPayer
            default:
                return true
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    Section {
                        AppPage1SummaryCard(
                            count: store.expenses.count,
                            totalAmount: store.totalAmount,
                            latestDate: store.latestExpenseDate,
                            currencyCode: store.settings.currencyCode
                        )
                    }

                    Section("新建账单") {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("聚会名称", text: $title)

                            TextField("金额", text: $amountString)
                                .keyboardType(.decimalPad)

                            TextField("付款人", text: $paidBy)

                            Stepper(value: $participantCount, in: 1...50) {
                                HStack {
                                    Text("参与人数")
                                    Spacer()
                                    Text("\(participantCount)")
                                }
                            }

                            Toggle("付款人也参与分摊", isOn: $payerIncluded)

                            DatePicker(
                                "日期",
                                selection: $date,
                                displayedComponents: [.date, .hourAndMinute]
                            )

                            TextField("备注", text: $note)

                            Button {
                                saveExpense()
                            } label: {
                                Text("保存账单")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!canSave)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    if filteredExpenses.isEmpty {
                        if store.expenses.isEmpty {
                            ContentUnavailableView {
                                Label("暂无账单", systemImage: "tray")
                            } description: {
                                Text("录入第一笔聚会花费，开始分摊")
                            } actions: {
                                Button("去填写") {
                                    searchText = ""
                                }
                            }
                        } else {
                            ContentUnavailableView.search(text: searchText)
                        }
                    } else {
                        ForEach(filteredExpenses) { expense in
                            NavigationLink(destination: AppPage1DetailView(expense: expense)) {
                                AppPage1ExpenseRow(
                                    expense: expense,
                                    currencyCode: store.settings.currencyCode
                                )
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(expense)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete(perform: deleteExpenses)
                    }
                } header: {
                    HStack {
                        Text("最近记录")
                        Spacer()
                        if !store.expenses.isEmpty {
                            Picker("筛选", selection: $payerFilter) {
                                Text("全部").tag(0)
                                Text("我付").tag(1)
                                Text("别人付").tag(2)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                        }
                    }
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "搜索账单或付款人"
            )
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("记一笔")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !store.expenses.isEmpty {
                        EditButton()
                    }
                }
            }
            .onAppear {
                if !didLoadDefaults {
                    paidBy = store.settings.defaultPayer
                    participantCount = max(1, store.settings.defaultParticipantCount)
                    didLoadDefaults = true
                }
            }
            .alert("已保存", isPresented: $showSaveAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text("账单已加入列表")
            }
            .environment(\.locale, Locale(identifier: "zh_CN"))
        }
    }

    private func saveExpense() {
        let participants = buildParticipants()

        let expense = AppExpense(id: UUID(), title: title.trimmingCharacters(in: .whitespacesAndNewlines), amount: amount, paidBy: paidBy.trimmingCharacters(in: .whitespacesAndNewlines), participants: participants, date: date, note: note.trimmingCharacters(in: .whitespacesAndNewlines))

        store.add(expense)
        store.save()

        title = ""
        amountString = ""
        note = ""
        date = Date()
        showSaveAlert = true
    }

    private func buildParticipants() -> [String] {
        var people = (1...participantCount).map { "成员\($0)" }

        if payerIncluded && !people.contains(paidBy) {
            people.insert(paidBy, at: 0)
        } else if !payerIncluded {
            people.removeAll { $0 == paidBy }
        }

        return people
    }

    private func delete(_ expense: AppExpense) {
        store.expenses.removeAll { $0.id == expense.id }
        store.save()
    }

    private func deleteExpenses(at offsets: IndexSet) {
        let targets = offsets.map { filteredExpenses[$0] }
        store.expenses.removeAll { expense in
            targets.contains { $0.id == expense.id }
        }
        store.save()
    }
}

struct AppPage1SummaryCard: View {
    let count: Int
    let totalAmount: Double
    let latestDate: Date?
    let currencyCode: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("共 \(count) 笔")
                    .font(.headline)

                if let latestDate {
                    Text("最近 \(AppPage1DateFormatter.string(from: latestDate))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("还没有记录")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("合计")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(AppPage1AmountString(totalAmount, currencyCode: currencyCode))
                    .font(.title3.bold())
            }
        }
        .padding(4)
    }
}

struct AppPage1ExpenseRow: View {
    let expense: AppExpense
    let currencyCode: String

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.headline)

                Text("\(expense.paidBy) · \(expense.participants.count)人")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(AppPage1DateFormatter.string(from: expense.date))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text(AppPage1AmountString(expense.amount, currencyCode: currencyCode))
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 2)
    }
}

struct AppPage1DetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    let expense: AppExpense

    @State private var title: String
    @State private var amountString: String
    @State private var paidBy: String
    @State private var participantCount: Int
    @State private var payerIncluded: Bool
    @State private var date: Date
    @State private var note: String
    @State private var showDiscardAlert = false
    @State private var showValidationAlert = false

    init(expense: AppExpense) {
        self.expense = expense
        _title = State(initialValue: expense.title)
        _amountString = State(initialValue: String(format: "%.2f", expense.amount))
        _paidBy = State(initialValue: expense.paidBy)
        _note = State(initialValue: expense.note)
        _date = State(initialValue: expense.date)

        let containsPayer = expense.participants.contains(expense.paidBy)
        _payerIncluded = State(initialValue: containsPayer)
        _participantCount = State(
            initialValue: max(1, expense.participants.count - (containsPayer ? 1 : 0))
        )
    }

    var amount: Double {
        Double(amountString) ?? 0
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        amount > 0 &&
        !paidBy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        participantCount > 0
    }

    private var originalParticipantCount: Int {
        let containsPayer = expense.participants.contains(expense.paidBy)
        return max(1, expense.participants.count - (containsPayer ? 1 : 0))
    }

    private var originalPayerIncluded: Bool {
        expense.participants.contains(expense.paidBy)
    }

    private var isDirty: Bool {
        title != expense.title ||
        amountString != String(format: "%.2f", expense.amount) ||
        paidBy != expense.paidBy ||
        date != expense.date ||
        note != expense.note ||
        participantCount != originalParticipantCount ||
        payerIncluded != originalPayerIncluded
    }

    var body: some View {
        Form {
            Section("账单信息") {
                TextField("聚会名称", text: $title)

                TextField("金额", text: $amountString)
                    .keyboardType(.decimalPad)

                TextField("付款人", text: $paidBy)

                Stepper(value: $participantCount, in: 1...50) {
                    HStack {
                        Text("参与人数")
                        Spacer()
                        Text("\(participantCount)")
                    }
                }

                Toggle("付款人也参与分摊", isOn: $payerIncluded)

                DatePicker(
                    "日期",
                    selection: $date,
                    displayedComponents: [.date, .hourAndMinute]
                )

                TextField("备注", text: $note)
            }

            Section {
                Button("保存修改") {
                    saveChanges()
                }
                .disabled(!canSave)
            }
        }
        .navigationTitle("账单详情")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    if isDirty {
                        showDiscardAlert = true
                    } else {
                        dismiss()
                    }
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    saveChanges()
                }
                .disabled(!canSave)
            }
        }
        .alert("放弃修改？", isPresented: $showDiscardAlert) {
            Button("继续编辑", role: .cancel) {}
            Button("放弃", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("未保存的修改会丢失")
        }
        .alert("金额无效", isPresented: $showValidationAlert) {
            Button("好", role: .cancel) {}
        } message: {
            Text("金额必须大于 0")
        }
        .environment(\.locale, Locale(identifier: "zh_CN"))
    }

    private func saveChanges() {
        guard canSave else {
            showValidationAlert = true
            return
        }

        let participants = buildParticipants()

        let updated = AppExpense(id: expense.id, title: title.trimmingCharacters(in: .whitespacesAndNewlines), amount: amount, paidBy: paidBy.trimmingCharacters(in: .whitespacesAndNewlines), participants: participants, date: date, note: note.trimmingCharacters(in: .whitespacesAndNewlines))

        if let index = store.expenses.firstIndex(where: { $0.id == expense.id }) {
            store.expenses[index] = updated
        }

        store.save()
        dismiss()
    }

    private func buildParticipants() -> [String] {
        var people = (1...participantCount).map { "成员\($0)" }

        if payerIncluded && !people.contains(paidBy) {
            people.insert(paidBy, at: 0)
        } else if !payerIncluded {
            people.removeAll { $0 == paidBy }
        }

        return people
    }
}