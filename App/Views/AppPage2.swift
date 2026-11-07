import SwiftUI
import Foundation

enum AppPage2Filter: String, CaseIterable, Identifiable {
    case all = "全部"
    case week = "近7天"
    case month = "近30天"

    var id: String { rawValue }
}

struct AppPage2View: View {
    @EnvironmentObject var store: AppStore
    @State private var filter: AppPage2Filter = .all

    private var filteredDays: [AppDaySummary] {
        let sorted = store.historyDays.sorted { $0.date > $1.date }
        switch filter {
        case .all:
            return sorted
        case .week:
            guard let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else {
                return sorted
            }
            return sorted.filter { $0.date >= cutoff }
        case .month:
            guard let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else {
                return sorted
            }
            return sorted.filter { $0.date >= cutoff }
        }
    }

    var totalML: Int {
        filteredDays.reduce(0) { $0 + $1.totalML }
    }

    private var averageML: Int {
        filteredDays.isEmpty ? 0 : totalML / filteredDays.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredDays.isEmpty {
                    AppPage2EmptyView()
                } else {
                    List {
                        Section {
                            AppPage2SummaryCard(
                                dayCount: filteredDays.count,
                                totalML: totalML,
                                averageML: averageML
                            )
                        }

                        Section {
                            Picker("范围", selection: $filter) {
                                ForEach(AppPage2Filter.allCases) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        Section {
                            ForEach(filteredDays) { day in
                                NavigationLink {
                                    AppPage2DetailView(day: day)
                                } label: {
                                    AppPage2DayRow(day: day, dailyGoalML: store.dailyGoalML)
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        deleteDay(day)
                                    } label: {
                                        Label("删除当天", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("历史")
        }
    }

    private func deleteDay(_ day: AppDaySummary) {
        withAnimation {
            store.entries.removeAll { entry in
                Calendar.current.isDate(entry.date, inSameDayAs: day.date)
            }
            store.save()
        }
    }
}

struct AppPage2SummaryCard: View {
    let dayCount: Int
    let totalML: Int
    let averageML: Int

    var body: some View {
        HStack {
            AppPage2SummaryItem(title: "记录天数", value: "\(dayCount)")
            Divider()
            AppPage2SummaryItem(title: "总喝水量", value: "\(totalML) 毫升")
            Divider()
            AppPage2SummaryItem(title: "日均", value: "\(averageML) 毫升")
        }
        .padding(.vertical, 8)
    }
}

struct AppPage2SummaryItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.headline, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AppPage2DayRow: View {
    let day: AppDaySummary
    let dailyGoalML: Int

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.dateString(day.date))
                    .font(.headline)
                Text("\(day.entries.count) 次记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(day.totalML) 毫升")
                    .font(.headline)
                Text("目标 \(dailyGoalML) 毫升")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEE"
        return formatter.string(from: date)
    }
}

struct AppPage2DetailView: View {
    @EnvironmentObject var store: AppStore
    let day: AppDaySummary

    var sortedEntries: [AppWaterEntry] {
        day.entries.sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppPage2DayRow.dateString(day.date))
                        .font(.title3.bold())

                    HStack {
                        Text("总喝水量")
                        Spacer()
                        Text("\(day.totalML) 毫升")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("记录次数")
                        Spacer()
                        Text("\(day.entries.count) 次")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("每日目标")
                        Spacer()
                        Text("\(store.dailyGoalML) 毫升")
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(
                        value: Double(day.totalML),
                        total: Double(max(store.dailyGoalML, 1))
                    ) {
                        Text("达标进度")
                            .font(.caption)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("记录") {
                ForEach(sortedEntries) { entry in
                    AppPage2EntryRow(entry: entry)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("历史详情")
        .navigationBarTitleDisplayMode(.inline)
        .contentMargins(.bottom, 96, for: .scrollContent)
    }
}

struct AppPage2EntryRow: View {
    let entry: AppWaterEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.amountML) 毫升")
                    .font(.headline)
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Text(Self.timeString(entry.date))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    static func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct AppPage2EmptyView: View {
    var body: some View {
        ContentUnavailableView {
            Label("暂无历史记录", systemImage: "drop")
        } description: {
            Text("从今天开始记录喝水，这里会按天汇总。")
        }
    }
}