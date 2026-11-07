import SwiftUI

fileprivate let AppPage2DayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M月d日 EEEE"
    return formatter
}()

fileprivate let AppPage2TimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "HH:mm"
    return formatter
}()

fileprivate let AppPage2MonthDayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M月d日"
    return formatter
}()

enum AppPage2Filter: String, CaseIterable, Identifiable {
    case all = "全部"
    case last7 = "近7天"
    case last30 = "近30天"
    var id: String { rawValue }
}

struct AppPage2View: View {
    @EnvironmentObject var store: AppStore
    @State private var filter: AppPage2Filter = .all
    
    private var filteredGroups: [AppDayGroup] {
        let groups = store.dayGroups
        switch filter {
        case .all:
            return groups
        case .last7:
            let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
            return groups.filter { $0.date >= cutoff }
        case .last30:
            let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
            return groups.filter { $0.date >= cutoff }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("筛选", selection: $filter) {
                        ForEach(AppPage2Filter.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    AppPage2SummaryCard(groups: filteredGroups)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                
                if filteredGroups.isEmpty {
                    Section {
                        AppPage2EmptyView()
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                } else {
                    Section {
                        ForEach(filteredGroups) { group in
                            NavigationLink {
                                AppPage2DayDetailView(dayID: group.id)
                            } label: {
                                AppPage2DayRow(group: group)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    deleteDay(group)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("历史")
        }
    }
    
    private func deleteDay(_ group: AppDayGroup) {
        store.records.removeAll { record in
            Calendar.current.isDate(record.date, inSameDayAs: group.date)
        }
        store.save()
    }
}

struct AppPage2SummaryCard: View {
    let groups: [AppDayGroup]
    
    private var totalAmount: Int {
        groups.reduce(0) { $0 + $1.total }
    }
    
    private var averageAmount: Int {
        groups.isEmpty ? 0 : totalAmount / groups.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("历史概览")
                .font(.headline)
                .foregroundStyle(.secondary)
            HStack(spacing: 0) {
                summaryItem(value: "\(groups.count)", label: "活跃天数")
                Divider()
                summaryItem(value: "\(totalAmount)", label: "累计毫升")
                Divider()
                summaryItem(value: "\(averageAmount)", label: "日均毫升")
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemBackground)))
    }
    
    private func summaryItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AppPage2DayRow: View {
    let group: AppDayGroup
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(AppPage2DayFormatter.string(from: group.date))
                    .font(.headline)
                Text("\(group.records.count) 条记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text("\(group.total) 毫升")
                    .font(.headline)
                ProgressView(value: Double(min(group.total, 2000)), total: 2000)
                    .frame(width: 100)
                    .tint(.cyan)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AppPage2EmptyView: View {
    var body: some View {
        ContentUnavailableView {
            Label("暂无历史记录", systemImage: "drop")
        } description: {
            Text("开始记录饮水后，这里会按天显示")
        } actions: {
            Button("去记录") {
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 32)
    }
}

struct AppPage2DayDetailView: View {
    let dayID: Date
    @EnvironmentObject var store: AppStore
    
    private var currentGroup: AppDayGroup? {
        store.dayGroups.first { $0.id == dayID }
    }
    
    var body: some View {
        List {
            if let group = currentGroup {
                Section {
                    AppPage2DetailHeader(group: group)
                }
                Section {
                    ForEach(group.records.sorted(by: { $0.date > $1.date })) { record in
                        AppPage2RecordRow(record: record)
                            .swipeActions {
                                Button(role: .destructive) {
                                    delete(record)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
            } else {
                Section {
                    ContentUnavailableView("这一天没有记录", systemImage: "drop")
                }
            }
        }
        .listStyle(.insetGrouped)
        .contentMargins(.bottom, 96, for: .scrollContent)
        .navigationTitle(AppPage2MonthDayFormatter.string(from: dayID))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("清空当天") {
                    deleteAllInDay()
                }
                .disabled(currentGroup == nil)
            }
        }
    }
    
    func delete(_ record: AppDrinkRecord) {
        store.records.removeAll { $0.id == record.id }
        store.save()
    }
    
    private func deleteAllInDay() {
        store.records.removeAll { record in
            Calendar.current.isDate(record.date, inSameDayAs: dayID)
        }
        store.save()
    }
}

struct AppPage2DetailHeader: View {
    let group: AppDayGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(AppPage2DayFormatter.string(from: group.date))
                        .font(.headline)
                    Text("\(group.records.count) 条记录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(group.total) 毫升")
                    .font(.title2.bold())
            }
            ProgressView(value: Double(min(group.total, 2000)), total: 2000)
                .tint(.cyan)
            HStack {
                Label("目标 2000 毫升", systemImage: "target")
                Spacer()
                Label("达成 \(Int(Double(group.total) / 2000.0 * 100))%", systemImage: "percent")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct AppPage2RecordRow: View {
    let record: AppDrinkRecord
    
    var body: some View {
        HStack {
            Image(systemName: "drop.fill")
                .foregroundStyle(.cyan)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(record.amount) 毫升")
                    .font(.headline)
                Text(AppPage2TimeFormatter.string(from: record.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(record.amount / 250) 杯")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}