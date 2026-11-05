import SwiftUI

struct AppHistoryView: View {
    @EnvironmentObject var store: AppGrowthStore
    @State private var editingRecord: AppGrowthRecord?

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("成长记录")
        }
        .sheet(item: $editingRecord) { record in
            AppEditRecordSheet(record: record) { updated in
                store.update(updated)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("还没有成长记录")
                .font(.title2)
                .fontWeight(.semibold)
            Text("去“记一笔”添加第一条身高体重数据吧")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var historyList: some View {
        List {
            ForEach(monthGroups) { group in
                Section(header: Text(group.title)) {
                    ForEach(group.records) { record in
                        Button {
                            editingRecord = record
                        } label: {
                            AppHistoryRow(record: record)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                withAnimation {
                                    store.delete(record)
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            Button {
                                editingRecord = record
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var monthGroups: [MonthGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.records) { record -> Date in
            let components = calendar.dateComponents([.year, .month], from: record.date)
            return calendar.date(from: components) ?? record.date
        }
        return grouped.map { monthDate, records in
            MonthGroup(
                id: monthDate,
                title: Self.monthFormatter.string(from: monthDate),
                records: records.sorted { $0.date > $1.date }
            )
        }
        .sorted { $0.id > $1.id }
    }
}

private struct MonthGroup: Identifiable {
    let id: Date
    let title: String
    let records: [AppGrowthRecord]
}

private struct AppHistoryRow: View {
    let record: AppGrowthRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.date, format: .dateTime.month().day())
                    .font(.headline)
                Text("身高: \(String(format: "%.1f", record.height)) cm  体重: \(String(format: "%.1f", record.weight)) kg")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct AppEditRecordSheet: View {
    let record: AppGrowthRecord
    let onSave: (AppGrowthRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var date: Date
    @State private var heightString: String
    @State private var weightString: String
    @State private var showAlert = false

    init(record: AppGrowthRecord, onSave: @escaping (AppGrowthRecord) -> Void) {
        self.record = record
        self.onSave = onSave
        _date = State(initialValue: record.date)
        _heightString = State(initialValue: String(format: "%.1f", record.height))
        _weightString = State(initialValue: String(format: "%.1f", record.weight))
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("日期", selection: $date, displayedComponents: .date)
                TextField("身高 (cm)", text: $heightString)
                    .keyboardType(.decimalPad)
                TextField("体重 (kg)", text: $weightString)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                }
            }
            .alert("输入无效", isPresented: $showAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text("请输入有效的身高和体重数字。")
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        let normalizedHeight = heightString.replacingOccurrences(of: ",", with: ".")
        let normalizedWeight = weightString.replacingOccurrences(of: ",", with: ".")
        guard let height = Double(normalizedHeight),
              let weight = Double(normalizedWeight),
              height > 0, weight > 0 else {
            showAlert = true
            return
        }
        var updated = record
        updated.date = date
        updated.height = height
        updated.weight = weight
        onSave(updated)
        dismiss()
    }
}