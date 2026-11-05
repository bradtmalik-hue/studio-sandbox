import SwiftUI

struct AppHistoryView: View {
    @EnvironmentObject private var store: AppGrowthStore
    @State private var selectedRecord: AppGrowthRecord?

    private var sections: [(monthKey: String, monthTitle: String, records: [AppGrowthRecord])] {
        let grouped = Dictionary(grouping: store.records) { record -> String in
            let components = Calendar.current.dateComponents([.year, .month], from: record.date)
            return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
        }
        let sortedKeys = grouped.keys.sorted(by: >)
        return sortedKeys.map { key in
            let records = (grouped[key] ?? []).sorted { $0.date > $1.date }
            let monthTitle = Self.monthTitle(for: key)
            return (key, monthTitle, records)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    ContentUnavailableView(
                        "还没有成长记录",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("点击下方\"记一笔\"，添加孩子的身高体重数据")
                    )
                } else {
                    List {
                        ForEach(sections, id: \.monthKey) { section in
                            Section(header: Text(section.monthTitle)) {
                                ForEach(section.records) { record in
                                    Button {
                                        selectedRecord = record
                                    } label: {
                                        AppHistoryRecordRow(record: record)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("历史记录")
            .sheet(item: $selectedRecord) { record in
                AppEditRecordView(record: record)
            }
        }
    }

    private static func monthTitle(for monthKey: String) -> String {
        let components = monthKey.split(separator: "-").compactMap { Int($0) }
        guard components.count == 2, let year = components.first, let month = components.last else {
            return monthKey
        }
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        if let date = Calendar.current.date(from: dateComponents) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年M月"
            return formatter.string(from: date)
        }
        return monthKey
    }
}

struct AppHistoryRecordRow: View {
    let record: AppGrowthRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("身高 \(record.heightCm, specifier: "%.1f") cm")
                    .font(.headline)
                Text("体重 \(record.weightKg, specifier: "%.2f") kg")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}