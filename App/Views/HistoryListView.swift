import SwiftUI
import Foundation

struct HistoryListView: View {
    @EnvironmentObject var store: AppGrowthStore
    @State private var editingRecord: AppGrowthRecord?
    @State private var isEditingPresented = false

    private struct HistoryMonthSection: Identifiable {
        let id: Date
        let month: Date
        let records: [AppGrowthRecord]
    }

    private var sections: [HistoryMonthSection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.records) { record -> Date in
            let components = calendar.dateComponents([.year, .month], from: record.date)
            return calendar.date(from: components) ?? record.date
        }
        return grouped.map { month, records in
            HistoryMonthSection(id: month, month: month, records: records.sorted { $0.date > $1.date })
        }
        .sorted { $0.month > $1.month }
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    var body: some View {
        Group {
            if sections.isEmpty {
                ContentUnavailableView {
                    Label("还没有记录", systemImage: "chart.xyaxis.line")
                } description: {
                    Text("点击“记一笔”添加第一条身高体重")
                }
            } else {
                List {
                    ForEach(sections) { section in
                        Section(header: Text(Self.monthFormatter.string(from: section.month))) {
                            ForEach(section.records, id: \.id) { record in
                                Button {
                                    editingRecord = record
                                    isEditingPresented = true
                                } label: {
                                    recordRow(record)
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete { offsets in
                                let recordsToDelete = offsets.map { section.records[$0] }
                                for record in recordsToDelete {
                                    store.delete(record)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("历史记录")
        .sheet(isPresented: $isEditingPresented) {
            if let record = editingRecord {
                EntryFormView(store: store, record: record)
            }
        }
    }

    private func recordRow(_ record: AppGrowthRecord) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(Self.dayFormatter.string(from: record.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack(spacing: 16) {
                    Label {
                        Text(String(format: "%.1f cm", record.heightCm))
                    } icon: {
                        Image(systemName: "ruler")
                    }
                    Label {
                        Text(String(format: "%.1f kg", record.weightKg))
                    } icon: {
                        Image(systemName: "scalemass")
                    }
                }
                .font(.body)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.tertiary)
        }
    }
}