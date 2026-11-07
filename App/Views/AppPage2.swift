import SwiftUI

enum AppPage2Filter: String, CaseIterable {
    case all
    case met
    case unmet

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .met:
            return "达标"
        case .unmet:
            return "未达标"
        }
    }
}

enum AppPage2Text {
    static func milliliters(_ value: Double) -> String {
        "\(Int(value.rounded())) 毫升"
    }

    static func monthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    static func monthDayTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

private struct AppPage2DayGroup: Identifiable {
    let id: Date
    let date: Date
    let total: Double
    let records: [AppWaterRecord]
}

struct AppPage2View: View {
    @EnvironmentObject var store: AppWaterStore
    @State private var filter: AppPage2Filter = .all

    private var groups: [AppPage2DayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.records) { record in
            calendar.startOfDay(for: record.date)
        }

        let all = grouped.map { day, records in
            AppPage2DayGroup(
                id: day,
                date: day,
                total: records.reduce(0) { $0 + $1.amount },
                records: records.sorted { $0.date > $1.date }
            )
        }
        .sorted { $0.date > $1.date }

        switch filter {
        case .all:
            return all
        case .met:
            return all.filter { $0.total >= 2000 }
        case .unmet:
            return all.filter { $0.total < 2000 }
        }
    }

    private var recordCount: Int {
        store.records.count
    }

    private var totalAmount: Double {
        store.records.reduce(0) { $0 + $1.amount }
    }

    private var latestDate: Date? {
        store.records.max(by: { $0.date < $1.date })?.date
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppPage2SummaryCard(
                    recordCount: recordCount,
                    totalAmount: totalAmount,
                    latestDate: latestDate
                )
                .padding(.horizontal)
                .padding(.top, 8)

                Picker("筛选", selection: $filter) {
                    ForEach(AppPage2Filter.allCases, id: \.self) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if groups.isEmpty {
                    AppPage2EmptyView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groups) { group in
                            Section {
                                ForEach(group.records) { record in
                                    AppPage2Row(record: record)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                delete(record)
                                            } label: {
                                                Label("删除", systemImage: "trash")
                                            }
                                        }
                                }
                            } header: {
                                AppPage2DayHeader(date: group.date, total: group.total)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("历史")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
        }
    }

    func delete(_ record: AppWaterRecord) {
        store.records.removeAll { $0.id == record.id }
        store.save()
    }
}

private struct AppPage2SummaryCard: View {
    let recordCount: Int
    let totalAmount: Double
    let latestDate: Date?

    var body: some View {
        HStack(spacing: 8) {
            AppPage2SummaryItem(
                title: "累计记录",
                value: "\(recordCount) 条",
                icon: "tray.full.fill"
            )
            Divider().frame(height: 36)
            AppPage2SummaryItem(
                title: "累计饮水",
                value: AppPage2Text.milliliters(totalAmount),
                icon: "drop.fill"
            )
            Divider().frame(height: 36)
            AppPage2SummaryItem(
                title: "最近一次",
                value: latestDate.map { AppPage2Text.monthDayTime($0) } ?? "—",
                icon: "clock.fill"
            )
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct AppPage2SummaryItem: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AppPage2DayHeader: View {
    let date: Date
    let total: Double

    var body: some View {
        HStack {
            Text(AppPage2Text.monthDay(date))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            Text(AppPage2Text.milliliters(total))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct AppPage2Row: View {
    let record: AppWaterRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(AppPage2Text.milliliters(record.amount))
                    .font(.headline)
                Text(AppPage2Text.time(record.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("约 \(String(format: "%.1f", record.amount / 250.0)) 杯")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}