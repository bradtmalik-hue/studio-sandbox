import Foundation
import Combine
import SwiftUI

struct AppHistoryView: View {
    @EnvironmentObject var store: AppGrowthStore
    @State private var selectedMonth: Date = Date()
    @State private var editRecord: AppGrowthRecord?

    private var sortedMonths: [Date] {
        store.groupedByMonth.map(\.monthStart).sorted()
    }

    private var currentIndex: Int? {
        sortedMonths.firstIndex { Calendar.current.isDate($0, equalTo: selectedMonth, toGranularity: .month) }
    }

    private var selectedGroup: AppGrowthMonthGroup? {
        store.groupedByMonth.first { Calendar.current.isDate($0.monthStart, equalTo: selectedMonth, toGranularity: .month) }
    }

    private var currentMonthRecords: [AppGrowthRecord] {
        selectedGroup?.records ?? []
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: selectedMonth)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthNavigationBar

                if store.groupedByMonth.isEmpty {
                    emptyState
                } else if currentMonthRecords.isEmpty {
                    emptyMonthState
                } else {
                    recordsList
                }
            }
            .navigationTitle("历史记录")
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            ensureValidMonth()
        }
        .sheet(item: $editRecord, onDismiss: {
            ensureValidMonth()
        }) { record in
            AppRecordEditSheet(record: record)
        }
    }

    private var monthNavigationBar: some View {
        HStack {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(currentIndex == nil || currentIndex == 0)

            Spacer()

            Text(monthTitle)
                .font(.headline)

            Spacer()

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(currentIndex == nil || currentIndex == sortedMonths.count - 1)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var recordsList: some View {
        List {
            ForEach(currentMonthRecords) { record in
                Button {
                    editRecord = record
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(monthDayString(for: record.date))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 16) {
                                Label(String(format: "%.1f 厘米", record.heightCm), systemImage: "ruler")
                                Label(String(format: "%.2f 公斤", record.weightKg), systemImage: "scalemass")
                            }
                            .font(.body)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("暂无记录")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyMonthState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("该月暂无记录")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func monthDayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    private func moveMonth(by offset: Int) {
        guard let index = currentIndex else { return }
        let newIndex = index + offset
        guard sortedMonths.indices.contains(newIndex) else { return }
        selectedMonth = sortedMonths[newIndex]
    }

    private func ensureValidMonth() {
        if let first = sortedMonths.first {
            if currentIndex == nil {
                selectedMonth = first
            }
        } else {
            selectedMonth = Date()
        }
    }
}