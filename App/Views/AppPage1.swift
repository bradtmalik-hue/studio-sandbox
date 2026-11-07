import SwiftUI

struct AppPage1View: View {
    @EnvironmentObject var store: AppStore
    @State private var customAmount: Double = 250

    private var todayRecords: [AppWaterRecord] {
        store.records.filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date > $1.date }
    }

    private var todayTotalMl: Double {
        todayRecords.reduce(0) { $0 + $1.amountMl }
    }

    private var remainingMl: Double {
        max(store.dailyGoalMl - todayTotalMl, 0)
    }

    var body: some View {
        NavigationStack {
            List {
                summarySection
                quickAddSection
                if todayRecords.isEmpty {
                    emptySection
                } else {
                    recordsSection
                }
            }
            .navigationTitle("今天")
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("今日已喝")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(todayTotalMl, specifier: "%.0f") 毫升")
                        .font(.title2.bold())
                        .monospacedDigit()
                }
                ProgressView(value: min(todayTotalMl, store.dailyGoalMl), total: max(store.dailyGoalMl, 1))
                    .tint(.blue)
                HStack {
                    Text("目标 \(store.dailyGoalMl, specifier: "%.0f") 毫升")
                    Spacer()
                    if remainingMl > 0 {
                        Text("还差 \(remainingMl, specifier: "%.0f") 毫升")
                            .foregroundStyle(.orange)
                    } else {
                        Text("已达标 🎉")
                            .foregroundStyle(.green)
                    }
                }
                .font(.footnote)
            }
            .padding(.vertical, 8)
        }
    }

    private var quickAddSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("快速记录")
                    .font(.headline)
                HStack(spacing: 8) {
                    ForEach([150.0, 250.0, 350.0, 500.0], id: \.self) { amount in
                        Button {
                            addRecord(amount: amount)
                        } label: {
                            Text("\(Int(amount)) 毫升")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack {
                    Text("自定义")
                    Spacer()
                    Stepper(value: $customAmount, in: 50...1500, step: 50) {
                        Text("\(Int(customAmount)) 毫升")
                            .monospacedDigit()
                    }
                }
                Button {
                    addRecord(amount: customAmount)
                } label: {
                    Label("记录本次喝水", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .disabled(customAmount <= 0)
            }
            .padding(.vertical, 8)
        }
    }

    private var recordsSection: some View {
        Section("今日记录") {
            ForEach(todayRecords) { record in
                AppPage1RecordRow(record: record, dailyGoal: store.dailyGoalMl)
                    .swipeActions {
                        Button(role: .destructive) {
                            deleteRecord(record)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
        }
    }

    private var emptySection: some View {
        Section {
            ContentUnavailableView {
                Label("今天还没喝水", systemImage: "drop")
            } description: {
                Text("点下面按钮记录第一杯水")
            } actions: {
                Button("添加第一条") {
                    customAmount = 250
                    addRecord(amount: 250)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 24)
        }
    }

    func addRecord(amount: Double) {
        guard amount > 0 else { return }
        let record = AppWaterRecord(id: UUID(), date: Date(), amountMl: amount)
        var newRecords = store.records
        newRecords.append(record)
        store.records = newRecords
        store.save()
    }

    func deleteRecord(_ record: AppWaterRecord) {
        var newRecords = store.records
        newRecords.removeAll { $0.id == record.id }
        store.records = newRecords
        store.save()
    }
}

struct AppPage1RecordRow: View {
    let record: AppWaterRecord
    let dailyGoal: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedTime(record.date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(Int(record.amountMl)) 毫升")
                    .font(.headline)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(record.amountMl >= dailyGoal ? "达标" : "\(Int(record.amountMl / max(dailyGoal, 1) * 100))%")
                    .font(.caption)
                    .foregroundStyle(record.amountMl >= dailyGoal ? .green : .secondary)
                ProgressView(value: min(record.amountMl, dailyGoal), total: max(dailyGoal, 1))
                    .frame(width: 80)
            }
        }
        .padding(.vertical, 4)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}