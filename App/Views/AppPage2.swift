import SwiftUI
import Foundation

private enum AppPage2FilterRange: String, CaseIterable, Identifiable {
    case all = "全部"
    case last7 = "近7天"
    case last30 = "近30天"

    var id: String { rawValue }
}

struct AppPage2DayGroup: Identifiable {
    let id: Date
    let date: Date
    let totalML: Int
    let records: [AppWaterRecord]
}

private enum AppPage2Formatters {
    static let day: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static func dayText(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "今天" }
        if calendar.isDateInYesterday(date) { return "昨天" }
        return day.string(from: date)
    }
}

struct AppPage2View: View {
    @EnvironmentObject var store: AppStore
    @State private var filterRange: AppPage2FilterRange = .all

    private var dayGroups: [AppPage2DayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.records) { record in
            calendar.startOfDay(for: record.date)
        }
        return grouped.map { date, records in
            AppPage2DayGroup(
                id: date,
                date: date,
                totalML: records.reduce(0) { $0 + $1.amountML },
                records: records.sorted { $0.date > $1.date }
            )
        }
        .sorted { $0.date > $1.date }
    }

    private var filterStartDate: Date {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        switch filterRange {
        case .all:
            return .distantPast
        case .last7:
            return calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
        case .last30:
            return calendar.date(byAdding: .day, value: -29, to: startOfToday) ?? startOfToday
        }
    }

    private var filteredDayGroups: [AppPage2DayGroup] {
        let start = filterStartDate
        return dayGroups.filter { $0.date >= start }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    ContentUnavailableView(
                        "还没有喝水记录",
                        systemImage: "drop",
                        description: Text("去「今天」添加第一条记录")
                    )
                } else if filteredDayGroups.isEmpty {
                    ContentUnavailableView(
                        "该时间段没有记录",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("试试切换筛选范围")
                    )
                } else {
                    List {
                        Section {
                            AppPage2SummaryView()
                        }
                        Section {
                            Picker("筛选范围", selection: $filterRange) {
                                ForEach(AppPage2FilterRange.allCases) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        Section("历史记录") {
                            ForEach(filteredDayGroups) { group in
                                NavigationLink {
                                    AppPage2DayDetailView()
                                } label: {
                                    AppPage2HistoryRow(day: group, dailyGoalML: store.dailyGoalML)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        let calendar = Calendar.current
                                        store.records.removeAll {
                                            calendar.isDate($0.date, inSameDayAs: group.date)
                                        }
                                        store.save()
                                    } label: {
                                        Label("删除当天", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("历史")
        }
    }
}

private struct AppPage2SummaryItem: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AppPage2HistoryRow: View {
    let day: AppPage2DayGroup
    let dailyGoalML: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppPage2Formatters.dayText(day.date))
                    .font(.headline)
                Text("\(day.records.count) 条记录")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(day.totalML) 毫升")
                    .font(.title3.bold())
                if dailyGoalML > 0 {
                    Text("\(Int(Double(day.totalML) / Double(dailyGoalML) * 100))% 目标")
                        .font(.caption2)
                        .foregroundStyle(day.totalML >= dailyGoalML ? Color.green : Color.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}