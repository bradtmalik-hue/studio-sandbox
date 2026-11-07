import SwiftUI

struct AppPage3View: View {
    @EnvironmentObject var store: AppStore
    var date: Date = Date()

    var dayRecords: [AppWaterRecord] {
        store.records
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }

    var totalML: Int {
        dayRecords.reduce(0) { $0 + $1.amountML }
    }

    var goal: Int {
        max(store.dailyGoalML, 1)
    }

    var progress: Double {
        min(Double(totalML) / Double(goal), 1.0)
    }

    private var shareText: String {
        let formatter = Self.detailDateFormatter
        let lines = dayRecords.map {
            "\(formatter.string(from: $0.date)) \($0.amountML)毫升 \($0.note)"
        }
        return "\(Self.summaryDateFormatter.string(from: date)) 喝水明细\n" + lines.joined(separator: "\n")
    }

    var body: some View {
        Group {
            if dayRecords.isEmpty {
                AppPage3Empty(date: date)
            } else {
                List {
                    AppPage3SummaryCard(
                        date: date,
                        totalML: totalML,
                        count: dayRecords.count,
                        goal: store.dailyGoalML
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)

                    ForEach(dayRecords) { record in
                        AppPage3Row(record: record)
                            .swipeActions {
                                Button(role: .destructive) {
                                    store.delete(record)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.insetGrouped)
                .contentMargins(.bottom, 96, for: .scrollContent)
            }
        }
        .navigationTitle("当天明细")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !dayRecords.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private static let detailDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    private static let summaryDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter
    }()
}

private struct AppPage3SummaryCard: View {
    let date: Date
    let totalML: Int
    let count: Int
    let goal: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Self.dateFormatter.string(from: date))
                        .font(.headline)
                    Text("\(count) 条记录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("总量")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(totalML) 毫升")
                        .font(.title2.bold())
                }
            }

            ProgressView(value: Double(totalML), total: Double(max(goal, 1)))
                .tint(Color.blue)

            HStack {
                Text("目标 \(goal) 毫升")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(totalML >= goal ? "已达标" : "还差 \(goal - totalML) 毫升")
                    .font(.caption)
                    .foregroundStyle(totalML >= goal ? Color.green : Color.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter
    }()
}

private struct AppPage3Row: View {
    let record: AppWaterRecord

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "drop.fill")
                .foregroundStyle(Color.blue)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.timeFormatter.string(from: record.date))
                    .font(.headline)
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Text("\(record.amountML) 毫升")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
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

private struct AppPage3Empty: View {
    @EnvironmentObject var store: AppStore
    let date: Date

    var body: some View {
        ContentUnavailableView {
            Label("这一天还没有记录", systemImage: "drop")
        } description: {
            Text("去今天页添加第一条喝水记录，或点击下方按钮手动补充 250 毫升。")
        } actions: {
            Button("添加 250 毫升") {
                let record = AppWaterRecord(
                    id: UUID(),
                    date: date,
                    amountML: 250,
                    note: "手动添加"
                )
                store.add(record)
            }
            .buttonStyle(.borderedProminent)

            Button("返回") {
                dismissal()
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    private func dismissal() {
        dismiss()
    }
}