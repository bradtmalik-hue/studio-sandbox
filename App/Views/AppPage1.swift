import SwiftUI
import Foundation

struct AppPage1View: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var showingAddSheet = false
    
    private var filteredExpenses: [AppExpense] {
        let all = store.todayExpenses
        guard !searchText.isEmpty else { return all }
        return all.filter { expense in
            expense.note.localizedCaseInsensitiveContains(searchText) ||
            expense.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                summarySection
                if filteredExpenses.isEmpty {
                    emptySection
                } else {
                    ForEach(filteredExpenses) { expense in
                        AppPage1Row(expense: expense)
                            .swipeActions {
                                Button(role: .destructive) {
                                    store.delete(expense)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("今天")
            .searchable(text: $searchText, prompt: "搜索备注或分类")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("记一笔", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AppPage1AddSheet()
                    .environmentObject(store)
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }
    
    var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text("今日合计")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(String(format: "¥%.2f", store.todayTotal))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(store.isOverBudget ? .red : .primary)
                HStack {
                    Text("共 \(store.todayExpenses.count) 笔")
                    Spacer()
                    if let last = store.todayExpenses.first {
                        Text("最近: \(formatDate(last.date))")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                if store.isOverBudget {
                    Label("已超过本月预算", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    var emptySection: some View {
        Section {
            ContentUnavailableView {
                Label("今天还没有支出", systemImage: "tray")
            } description: {
                Text("点击下方加号，记录今天的第一笔")
            } actions: {
                Button("添加第一条") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

struct AppPage1Row: View {
    let expense: AppExpense
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 36, height: 36)
                .background(.quaternary, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.note.isEmpty ? expense.category.rawValue : expense.note)
                    .font(.body)
                    .lineLimit(1)
                Text(expense.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "¥%.2f", expense.amount))
                    .font(.headline)
                Text(formatTime(expense.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var iconName: String {
        switch expense.category {
        case .dining: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct AppPage1AddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore
    
    @State private var amountText = ""
    @State private var category: AppCategory = .dining
    @State private var note = ""
    @State private var date = Date()
    @State private var useNow = false
    
    private var isAmountValid: Bool {
        guard let value = Double(amountText), value > 0 else { return false }
        return true
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("金额") {
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                Section("分类") {
                    Picker("分类", selection: $category) {
                        ForEach(AppCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("备注") {
                    TextField("备注（可选）", text: $note)
                }
                Section("时间") {
                    Toggle("使用当前时间", isOn: $useNow)
                    if !useNow {
                        DatePicker("日期与时间", selection: $date)
                    }
                }
            }
            .navigationTitle("记一笔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let amount = Double(amountText) ?? 0
                        let expense = AppExpense(
                            id: UUID(),
                            amount: amount,
                            category: category,
                            note: note,
                            date: useNow ? Date() : date
                        )
                        store.add(expense)
                        dismiss()
                    }
                    .disabled(!isAmountValid)
                }
            }
        }
    }
}