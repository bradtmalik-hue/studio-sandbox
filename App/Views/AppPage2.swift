import SwiftUI
import Foundation

private let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M月d日"
    return formatter
}()

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M月d日 HH:mm"
    return formatter
}()

struct AppPage2View: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedFilter: AppPage2Filter = .all
    @State private var showAddSheet = false
    @State private var showGoTodayAlert = false

    private var daySummaries: [AppPage2DaySummary] {
        let grouped = Dictionary(grouping: store.records) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.map { day, records in
            AppPage2DaySummary(day: day, records: records, id: Date(), totalMl: 0, recordCount: 0)
        }
        .sorted { $0.day > $1.day }
    }

    private var filteredSummaries: [AppPage2DaySummary] {
        switch selectedFilter {
        case .all:
            return daySummaries
        case .met:
            return daySummaries.filter { $0.totalMl >= store.dailyGoalMl }
        case .notMet:
            return daySummaries.filter { $0.totalMl < store.dailyGoalMl }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    ContentUnavailableView {
                        Label("暂无历史记录", systemImage: "drop")
                    } description: {
                        Text("记录每天喝水，回顾达标情况")
                    } actions: {
                        Button("去今天记录") {
                            showGoTodayAlert = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .alert("提示", isPresented: $showGoTodayAlert) {
                        Button("知道了", role: .cancel) { }
                    } message: {
                        Text("请前往“今天”页添加记录")
                    }
                } else {
                    List {
                        AppPage2SummarySection(records: store.records)
                        AppPage2FilterSection(filter: $selectedFilter)
                        ForEach(filteredSummaries) { summary in
                            NavigationLink(destination: AppPage2DayDetailView(day: summary.day, records: "", dailyGoal: 0)) {
                                AppPage2DayRow(summary: summary, dailyGoalMl: store.dailyGoalMl)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteDay(summary)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                        Color.clear.frame(height: 96)
                    }
                    .contentMargins(.bottom, 96, for: .scrollContent)
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("历史")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AppPage2AddRecordSheet()
            }
        }
    }

    private func deleteDay(_ summary: AppPage2DaySummary) {
        withAnimation {
            store.records.removeAll { Calendar.current.isDate($0.date, inSameDayAs: summary.day) }
            store.save()
        }
    }
}

enum AppPage2Filter: String, CaseIterable, Identifiable {
    case all
    case met
    case notMet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .met:
            return "达标"
        case .notMet:
            return "未达标"
        }
    }
}

struct AppPage2DaySummary: Identifiable {
    let day: Date
    let records: [AppWaterRecord]

    var id: Date { day }
    var totalMl: Double { records.reduce(0) { $0 + $1.amountMl } }
    var recordCount: Int { records.count }
}

struct AppPage2DayRow: View {
    let summary: AppPage2DaySummary
    let dailyGoalMl: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dayFormatter.string(from: summary.day))
                    .font(.headline)
                Text("\(summary.recordCount) 次 · \(Int(summary.totalMl)) 毫升")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: summary.totalMl >= dailyGoalMl ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundStyle(summary.totalMl >= dailyGoalMl ? Color.green : Color.orange)
                Text("\(Int(summary.totalMl)) 毫升")
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AppPage2SummarySection: View {
    let records: [AppWaterRecord]

    private var totalMl: Double {
        records.reduce(0) { $0 + $1.amountMl }
    }

    private var lastDate: Date? {
        records.map(\.date).max()
    }

    private var totalDays: Int {
        Set(records.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    var body: some View {
        Section {
            HStack(spacing: 8) {
                AppPage2StatCard(title: "记录天数", value: "\(totalDays)", unit: "天")
                AppPage2StatCard(title: "总喝水量", value: "\(Int(totalMl))", unit: "毫升")
                AppPage2StatCard(title: "最近一次", value: lastDate.map { timeFormatter.string(from: $0) } ?? "—", unit: "")
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
}

struct AppPage2StatCard: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct AppPage2FilterSection: View {
    @Binding var filter: AppPage2Filter

    var body: some View {
        Section {
            Picker("筛选", selection: $filter) {
                ForEach(AppPage2Filter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

struct AppPage2DayDetailView: View {
    @EnvironmentObject var store: AppStore
    let day: Date

    var records: [AppWaterRecord] {
        store.records
            .filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.date < $1.date }
    }

    private var totalMl: Double {
        records.reduce(0) { $0 + $1.amountMl }
    }

    var dailyGoal: Double {
        store.dailyGoalMl
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text(dayFormatter.string(from: day))
                        .font(.headline)
                    Spacer()
                    Text("\(Int(totalMl)) 毫升")
                        .font(.headline)
                    Image(systemName: totalMl >= dailyGoal ? "checkmark.circle.fill" : "exclamationmark.circle")
                        .foregroundStyle(totalMl >= dailyGoal ? Color.green : Color.orange)
                }
                .padding(.vertical, 4)
            }
            Section("记录明细") {
                if records.isEmpty {
                    Text("这一天没有记录")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(records, id: \.id) { record in
                        HStack {
                            Text(timeFormatter.string(from: record.date))
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(record.amountMl)) 毫升")
                                .font(.subheadline)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteRecord(record)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("当天详情")
        .listStyle(.insetGrouped)
    }

    func deleteRecord(_ record: AppWaterRecord) {
        withAnimation {
            store.records.removeAll { $0.id == record.id }
            store.save()
        }
    }
}

struct AppPage2AddRecordSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("请在“今天”页添加", systemImage: "plus.circle")
            } description: {
                Text("历史页主要用于回顾，新增记录请前往今天页")
            }
            .navigationTitle("添加记录")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("知道了") {
                        dismiss()
                    }
                }
            }
        }
    }
}