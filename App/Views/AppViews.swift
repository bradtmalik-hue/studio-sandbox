import SwiftUI
import Foundation
import Combine

// MARK: - 日期格式化
enum AppDateFormatter {
    static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "HH:mm"
        return f
    }()
    
    static let full: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 HH:mm"
        return f
    }()
    
    static let dateOnly: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日"
        return f
    }()
}

// MARK: - 空状态视图
struct AppEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - 今天视图
struct AppTodayView: View {
    @EnvironmentObject var store: AppMealStore
    @State private var showingAddSheet = false
    
    private var todayRecords: [AppMealRecord] {
        store.records.filter { Calendar.current.isDateInToday($0.date) }
            .sorted(by: { $0.date > $1.date })
    }
    
    var body: some View {
        NavigationStack {
            List {
                if todayRecords.isEmpty {
                    Section {
                        AppEmptyStateView(
                            icon: "cat",
                            title: "今天还没有喂猫",
                            message: "点右上角的 + 记录第一次喂食"
                        )
                    }
                } else {
                    Section("今日概览") {
                        Label("已喂食 \(todayRecords.count) 次", systemImage: "checkmark.circle.fill")
                        if let last = todayRecords.first {
                            Label("最近一次：\(AppDateFormatter.timeOnly.string(from: last.date))", systemImage: "clock")
                            Label("喂食量：\(last.amount, specifier: "%.0f") 克", systemImage: "fork.knife")
                        }
                    }
                    Section("今日喂食记录") {
                        ForEach(todayRecords) { record in
                            AppMealRecordRow(record: record, showsDate: false)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
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
                AppAddMealView()
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }
}

// MARK: - 历史记录视图
struct AppHistoryView: View {
    @EnvironmentObject var store: AppMealStore
    @State private var showingAddSheet = false
    
    private var sortedRecords: [AppMealRecord] {
        store.records.sorted(by: { $0.date > $1.date })
    }
    
    var body: some View {
        NavigationStack {
            List {
                if sortedRecords.isEmpty {
                    Section {
                        AppEmptyStateView(
                            icon: "clock.arrow.circlepath",
                            title: "还没有任何喂食记录",
                            message: "添加记录后，这里会显示完整的喂食历史"
                        )
                    }
                } else {
                    Section("全部记录") {
                        ForEach(sortedRecords) { record in
                            AppMealRecordRow(record: record, showsDate: true)
                        }
                        .onDelete { offsets in
                            let sorted = sortedRecords
                            let ids = offsets.map { sorted[$0].id }
                            store.records.removeAll { ids.contains($0.id) }
                            store.save()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("喂食历史")
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
                AppAddMealView()
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }
}

// MARK: - 统计视图
struct AppStatsView: View {
    @EnvironmentObject var store: AppMealStore
    
    private var last7DaysRecords: [AppMealRecord] {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date()))!
        return store.records.filter { $0.date >= start }
    }
    
    private var averageAmount: Double {
        guard !last7DaysRecords.isEmpty else { return 0 }
        return last7DaysRecords.map(\.amount).reduce(0.0, +) / Double(last7DaysRecords.count)
    }
    
    private var totalAmount: Double {
        last7DaysRecords.map(\.amount).reduce(0.0, +)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("最近 7 天") {
                    Label("喂食次数：\(last7DaysRecords.count)", systemImage: "number.circle.fill")
                    Label("平均每次：\(averageAmount, specifier: "%.0f") 克", systemImage: "plusminus")
                    Label("总喂食量：\(totalAmount, specifier: "%.0f") 克", systemImage: "chart.bar.fill")
                }
                if store.records.isEmpty {
                    Section {
                        AppEmptyStateView(
                            icon: "chart.pie.fill",
                            title: "还没有统计数据",
                            message: "喂食记录会出现在这里"
                        )
                    }
                } else {
                    Section("最近 7 天明细") {
                        ForEach(last7DaysRecords.sorted(by: { $0.date > $1.date })) { record in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(AppDateFormatter.full.string(from: record.date))
                                        .font(.body)
                                    if let note = record.note {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text("\(record.amount, specifier: "%.0f") 克")
                                    .font(.headline)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("统计")
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }
}

// MARK: - 记录行
struct AppMealRecordRow: View {
    let record: AppMealRecord
    var showsDate: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(showsDate ? AppDateFormatter.full.string(from: record.date) : AppDateFormatter.timeOnly.string(from: record.date))
                    .font(.body)
                if let note = record.note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(record.amount, specifier: "%.0f") 克")
                .font(.headline)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 添加喂食记录视图
struct AppAddMealView: View {
    @EnvironmentObject var store: AppMealStore
    @Environment(\.dismiss) var dismiss
    
    @State private var date = Date()
    @State private var amount: Double = 50
    @State private var note: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("喂食时间") {
                    DatePicker("时间", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                Section("喂食量") {
                    Stepper(value: $amount, in: 1...500, step: 5) {
                        HStack {
                            Text("喂食量")
                            Spacer()
                            Text("\(amount, specifier: "%.0f") 克")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("备注（可选）") {
                    TextField("例如：猫粮、罐头", text: $note)
                }
            }
            .navigationTitle("添加记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let record = AppMealRecord(date: date, amount: amount, note: note.isEmpty ? nil : note)
                        store.add(record)
                        dismiss()
                    }
                }
            }
        }
    }
}