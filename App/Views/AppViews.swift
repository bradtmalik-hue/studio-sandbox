import SwiftUI
import Foundation

private enum AppViewFormatters {
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static let day: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    static let full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()
}

private struct AppDayGroup: Identifiable {
    let id: Date
    let records: [AppFeedingRecord]
}

struct AppTodayView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingAdd = false

    private var todayRecords: [AppFeedingRecord] {
        store.records.filter { Calendar.current.isDateInToday($0.date) }
    }

    private var totalAmount: Double {
        todayRecords.reduce(0) { $0 + $1.amount }
    }

    private var lastRecord: AppFeedingRecord? {
        todayRecords.max(by: { $0.date < $1.date })
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    summaryCard
                }
                Section("今日记录") {
                    if todayRecords.isEmpty {
                        emptyRow
                    } else {
                        ForEach(todayRecords) { record in
                            HStack {
                                Text(AppViewFormatters.time.string(from: record.date))
                                Spacer()
                                Text(String(format: "%.0f 克", record.amount))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("猫饭记")
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
                AppAddRecordView()
                    .environmentObject(store)
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "cat.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 4) {
                    Text("今天喂了 \(todayRecords.count) 次")
                        .font(.headline)
                    Text("共 \(String(format: "%.0f", totalAmount)) 克")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let last = lastRecord {
                    Text(AppViewFormatters.time.string(from: last.date))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            if todayRecords.isEmpty {
                Text("点击右上角 + 记录第一次喂食")
                    .font(.footnote)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyRow: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "cat")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("今天还没有喂猫记录")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 32)
            Spacer()
        }
    }
}

struct AppHistoryView: View {
    @EnvironmentObject var store: AppStore

    private var groupedRecords: [AppDayGroup] {
        let calendar = Calendar.current
        let sorted = store.records.sorted { $0.date > $1.date }
        let groups = Dictionary(grouping: sorted) { calendar.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in
            AppDayGroup(
                id: day,
                records: groups[day]!.sorted { $0.date > $1.date }
            )
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if store.records.isEmpty {
                    emptyState
                } else {
                    ForEach(groupedRecords) { group in
                        Section(header: Text(AppViewFormatters.day.string(from: group.id))) {
                            ForEach(group.records) { record in
                                HStack {
                                    Text(AppViewFormatters.time.string(from: record.date))
                                    Spacer()
                                    Text(String(format: "%.0f 克", record.amount))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .onDelete { offsets in
                                delete(offsets, from: group.records)
                            }
                        }
                    }
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("历史记录")
            .toolbar {
                EditButton()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("还没有喂食记录")
                .foregroundStyle(.secondary)
            Text("点击右上角 + 开始记录")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.top, 40)
    }

    func delete(_ offsets: IndexSet, from records: [AppFeedingRecord]) {
        let ids = offsets.map { records[$0].id }
        for id in ids {
            if let index = store.records.firstIndex(where: { $0.id == id }) {
                store.records.remove(at: index)
            }
        }
        store.save()
    }
}

struct AppAddRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore
    @State private var date = Date()
    @State private var amountText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("时间", selection: $date)
                    TextField("喂食量（克）", text: $amountText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("记录喂食")
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
        guard let amount = Double(amountText), amount > 0 else { return }
        let record = AppFeedingRecord(date: date, amount: amount)
        store.records.append(record)
        store.save()
        dismiss()
    }
}