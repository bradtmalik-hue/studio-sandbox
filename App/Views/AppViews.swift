import SwiftUI
import Foundation

private let appDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M月d日 HH:mm"
    return formatter
}()

private func formattedAmount(_ amount: Double) -> String {
    String(format: "%.1f 克", amount)
}

struct AppFeedingListView: View {
    @EnvironmentObject var store: AppFeedingStore
    @State private var showingAddSheet = false

    private var sortedRecords: [AppFeedingRecord] {
        store.records.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedRecords.isEmpty {
                    ContentUnavailableView(
                        "还没有喂食记录",
                        systemImage: "cat",
                        description: Text("点击右上角 + 记录第一次喂猫")
                    )
                } else {
                    List {
                        ForEach(sortedRecords) { record in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(appDateFormatter.string(from: record.date))
                                        .font(.headline)
                                    Text(formattedAmount(Double(record.amount)))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteRecords)
                    }
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("猫饭记")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AppAddFeedingView()
            }
        }
    }

    private func deleteRecords(at offsets: IndexSet) {
        let idsToDelete = offsets.map { sortedRecords[$0].id }
        store.records.removeAll { idsToDelete.contains($0.id) }
        store.save()
    }
}

struct AppAddFeedingView: View {
    @EnvironmentObject var store: AppFeedingStore
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var amountText = "30"

    var body: some View {
        NavigationStack {
            Form {
                Section("喂食时间") {
                    DatePicker("时间", selection: $date)
                }
                Section("喂食量") {
                    TextField("食量（克）", text: $amountText)
                        .keyboardType(.decimalPad)
                }
                Section {
                    Button("保存记录") {
                        addRecord()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(Double(amountText) == nil)
                }
            }
            .navigationTitle("新增喂食记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private func addRecord() {
        guard let amount = Double(amountText), amount > 0 else { return }
        let record = AppFeedingRecord(id: UUID(), date: date, amount: amount)
        store.records.append(record)
        store.save()
        dismiss()
    }
}

struct AppFeedingStatsView: View {
    @EnvironmentObject var store: AppFeedingStore

    private var todayRecords: [AppFeedingRecord] {
        let start = Calendar.current.startOfDay(for: Date())
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return [] }
        return store.records.filter { $0.date >= start && $0.date < end }
    }

    private var recentRecords: [AppFeedingRecord] {
        Array(store.records.sorted { $0.date > $1.date }.prefix(7))
    }

    private var todayTotal: Double {
        todayRecords.reduce(0.0) { $0 + Double($1.amount) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("今日概况") {
                    LabeledContent("喂食次数", value: "\(todayRecords.count) 次")
                    LabeledContent("总食量", value: formattedAmount(todayTotal))
                }
                Section("最近 7 条") {
                    if recentRecords.isEmpty {
                        Text("暂无记录")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(recentRecords) { record in
                            LabeledContent(
                                appDateFormatter.string(from: record.date),
                                value: formattedAmount(Double(record.amount))
                            )
                        }
                    }
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("统计")
        }
    }
}

struct AppFeedingSettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("使用提示") {
                    Label("点击右上角 + 记录每次喂猫的时间和食量", systemImage: "pencil")
                    Label("如果某天没有记录，说明可能漏喂了", systemImage: "calendar.badge.exclamationmark")
                }
                Section("数据") {
                    Label("所有数据仅保存在本机", systemImage: "internaldrive")
                }
                Section("关于") {
                    LabeledContent("版本", value: "1.0")
                    Text("猫饭记 · 记录每一餐")
                        .foregroundStyle(.secondary)
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("设置")
        }
    }
}

typealias AppFeedingRecordsView = AppFeedingListView
typealias AppRecordsView = AppFeedingListView
typealias AppStatsView = AppFeedingStatsView
typealias AppFeedingSummaryView = AppFeedingStatsView
typealias AppSettingsView = AppFeedingSettingsView
typealias AppFeedingPlanView = AppFeedingSettingsView