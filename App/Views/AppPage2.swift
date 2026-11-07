import SwiftUI
import Foundation
import Combine

struct AppPage2View: View {
    @EnvironmentObject private var store: AppStore
    @State private var filter: AppPage2Filter = .all

    private var filteredGroups: [AppPage2Group] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: store.records) { record -> Date in
            calendar.startOfDay(for: record.date)
        }
        let mapped = groups.map { date, records -> AppPage2Group in
            AppPage2Group(date: date, records: records.sorted { $0.date > $1.date })
        }
        let sorted = mapped.sorted { $0.date > $1.date }
        switch filter {
        case .all:
            return sorted
        case .met:
            return sorted.filter { $0.totalAmount >= 2000 }
        case .unmet:
            return sorted.filter { $0.totalAmount < 2000 }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage2SummaryCard(
                        count: store.records.count,
                        total: store.records.reduce(0) { $0 + $1.amount },
                        recentDate: store.records.max(by: { $0.date < $1.date })?.date
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Picker("筛选", selection: $filter) {
                    ForEach(AppPage2Filter.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)

                ForEach(filteredGroups) { group in
                    Section {
                        ForEach(group.records) { record in
                            NavigationLink {
                                AppPage2DetailView(record: record)
                            } label: {
                                AppPage2Row(record: record)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(record)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        AppPage2GroupHeader(date: group.date, total: group.totalAmount)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("历史")
            .contentMargins(.bottom, 96, for: .scrollContent)
            .overlay {
                if filteredGroups.isEmpty {
                    ContentUnavailableView {
                        Label("暂无历史记录", systemImage: "drop")
                    } description: {
                        Text("去今天页记录第一杯水吧")
                    } actions: {
                        Button("去记录") {
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
        }
    }

    func delete(_ record: AppDrinkRecord) {
        store.records.removeAll { $0.id == record.id }
        store.save()
    }
}

enum AppPage2Filter: String, CaseIterable, Identifiable {
    case all
    case met
    case unmet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "全部"
        case .met: return "达标"
        case .unmet: return "未达标"
        }
    }
}

struct AppPage2Group: Identifiable {
    let date: Date
    let records: [AppDrinkRecord]

    var id: Date { date }

    var totalAmount: Int {
        records.reduce(0) { $0 + $1.amount }
    }
}

struct AppPage2SummaryCard: View {
    let count: Int
    let total: Int
    let recentDate: Date?

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("总记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(count) 条")
                    .font(.title2.bold())
            }
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text("总饮水量")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(total) 毫升")
                    .font(.title2.bold())
            }
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text("最近一次")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(recentDate.map { Self.dateTimeFormatter.string(from: $0) } ?? "—")
                    .font(.subheadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()
}

struct AppPage2GroupHeader: View {
    let date: Date
    let total: Int

    var body: some View {
        HStack {
            Text(Self.dateFormatter.string(from: date))
                .font(.headline)
            Spacer()
            Text("合计 \(total) 毫升")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()
}

struct AppPage2Row: View {
    let record: AppDrinkRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("喝水")
                    .font(.body)
                Text(Self.timeFormatter.string(from: record.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(record.amount) 毫升")
                .font(.body.monospacedDigit())
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

struct AppPage2DetailView: View {
    let record: AppDrinkRecord

    var body: some View {
        List {
            Section {
                HStack {
                    Text("日期")
                    Spacer()
                    Text(Self.dateFormatter.string(from: record.date))
                }
                HStack {
                    Text("时间")
                    Spacer()
                    Text(Self.timeFormatter.string(from: record.date))
                }
                HStack {
                    Text("饮水量")
                    Spacer()
                    Text("\(record.amount) 毫升")
                }
            } header: {
                Text("记录详情")
            }
        }
        .navigationTitle("详情")
        .navigationBarTitleDisplayMode(.inline)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}