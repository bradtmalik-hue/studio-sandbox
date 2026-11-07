import SwiftUI
import Foundation

struct AppPage1View: View {
    @EnvironmentObject var store: AppStore

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    private var recentDateText: String {
        guard let recent = store.recentRecordDate else { return "暂无" }
        return Self.timeFormatter.string(from: recent)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                AppPage1ProgressCard(
                    progress: store.progress,
                    total: store.totalToday,
                    goal: store.dailyGoal
                )

                AppPage1SummaryCard(
                    count: store.todayRecords.count,
                    total: store.totalToday,
                    recentText: recentDateText
                )

                if store.todayRecords.isEmpty {
                    AppPage1EmptyView(onAdd: addRecord)
                    Spacer()
                } else {
                    List {
                        ForEach(store.todayRecords) { record in
                            AppPage1Row(
                                record: record,
                                timeText: Self.timeFormatter.string(from: record.date)
                            )
                            .swipeActions {
                                Button(role: .destructive) {
                                    delete(record)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }

                Button(action: addRecord) {
                    Label("添加 250 毫升", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("今天")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func addRecord() {
        let record = AppWaterRecord(
            id: UUID(),
            date: Date(),
            amount: 250,
            note: "快速添加"
        )
        store.records.append(record)
        store.save()
    }

    private func delete(_ record: AppWaterRecord) {
        store.records.removeAll { $0.id == record.id }
        store.save()
    }
}

struct AppPage1ProgressCard: View {
    var progress: Double
    var total: Double
    var goal: Double

    var body: some View {
        HStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 4) {
                    Text("\(Int(total))")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("毫升")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 140, height: 140)

            VStack(alignment: .leading, spacing: 12) {
                Text("今日喝水")
                    .font(.headline)
                Text("目标 \(Int(goal)) 毫升")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(progressText)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }

    private var progressText: String {
        if goal > 0 {
            return "\(Int(progress * 100))%"
        } else {
            return "未设置目标"
        }
    }
}

struct AppPage1SummaryCard: View {
    var count: Int
    var total: Double
    var recentText: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(count)")
                    .font(.headline)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text("合计")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(total)) 毫升")
                    .font(.headline)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text("最近")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(recentText)
                    .font(.headline)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }
}

struct AppPage1Row: View {
    var record: AppWaterRecord
    var timeText: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(record.amount)) 毫升")
                    .font(.headline)
                Text(record.note.isEmpty ? "无备注" : record.note)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(timeText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AppPage1EmptyView: View {
    var onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("今天还没喝水", systemImage: "drop")
        } description: {
            Text("点击下方按钮添加 250 毫升")
        } actions: {
            Button("添加 250 毫升", action: onAdd)
        }
    }
}