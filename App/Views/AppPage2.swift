import Foundation
import SwiftUI
import Combine

struct AppPage2View: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        List {
            summarySection

            if filteredRecords.isEmpty {
                AppPage2EmptyView(message: searchText.isEmpty ? "去今天的页面添加第一条饮水记录" : "没有与“\(searchText)”匹配的记录")
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.records) { record in
                            AppPage2RecordRow(record: record, timeFormatter: timeFormatter)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        delete(record)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                        }
                    } header: {
                        HStack {
                            Text(dayFormatter.string(from: group.day))
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(group.total) 毫升")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索种类或毫升数")
        .navigationTitle("历史")
        .contentMargins(.bottom, 96, for: .scrollContent)
    }

    var filteredRecords: [AppWaterRecord] {
        guard !searchText.isEmpty else { return store.records }
        return store.records.filter { record in
            record.kind.rawValue.localizedCaseInsensitiveContains(searchText) ||
            "\(record.amount)".contains(searchText)
        }
    }

    var groups: [AppPage2DayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredRecords) { calendar.startOfDay(for: $0.date) }
        return grouped.map { day, records in
            AppPage2DayGroup(day: day, records: records.sorted { $0.date > $1.date })
        }
        .sorted { $0.day > $1.day }
    }

    private var totalAmount: Int {
        store.records.reduce(0) { $0 + $1.amount }
    }

    private var totalCount: Int {
        store.records.count
    }

    private var latestText: String {
        guard let latest = store.records.max(by: { $0.date < $1.date }) else { return "暂无" }
        return dayFormatter.string(from: latest.date) + " " + timeFormatter.string(from: latest.date)
    }

    private var summarySection: some View {
        Section {
            HStack(spacing: 12) {
                AppPage2SummaryItem(title: "累计饮水", value: "\(totalAmount) 毫升", systemImage: "drop.circle.fill")
                AppPage2SummaryItem(title: "记录条数", value: "\(totalCount) 条", systemImage: "list.bullet.rectangle")
                AppPage2SummaryItem(title: "最近记录", value: latestText, systemImage: "clock")
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    func delete(_ record: AppWaterRecord) {
        withAnimation {
            store.records.removeAll { $0.id == record.id }
        }
        store.save()
    }
}

private struct AppPage2DayGroup: Identifiable {
    let day: Date
    let records: [AppWaterRecord]

    var id: Date { day }
    var total: Int { records.reduce(0) { $0 + $1.amount } }
}

private struct AppPage2RecordRow: View {
    let record: AppWaterRecord
    let timeFormatter: DateFormatter

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)
                .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(record.kind.rawValue)
                    .font(.headline)
                Text(timeFormatter.string(from: record.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("+\(record.amount) 毫升")
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
}

private struct AppPage2SummaryItem: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AppPage2EmptyView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("暂无历史记录", systemImage: "drop")
        } description: {
            Text(message)
        } actions: {
            Button("去添加") {
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}