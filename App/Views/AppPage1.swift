import SwiftUI
import Foundation

struct AppPage1View: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingAddSheet = false

    var todayRecords: [AppDrinkRecord] {
        store.records
            .filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date > $1.date }
    }

    var todayTotal: Int {
        todayRecords.reduce(0) { $0 + $1.amount }
    }

    private var progress: Double {
        let goal = max(store.dailyGoal, 1)
        return min(max(Double(todayTotal) / Double(goal), 0), 1)
    }

    var body: some View {
        NavigationStack {
            Group {
                if todayRecords.isEmpty {
                    AppPage1Empty {
                        showingAddSheet = true
                    }
                } else {
                    List {
                        Section {
                            AppPage1SummaryCard(
                                todayTotal: todayTotal,
                                goal: store.dailyGoal,
                                progress: progress
                            ) {
                                addQuickRecord()
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        }

                        Section {
                            ForEach(todayRecords) { record in
                                AppPage1Row(record: record)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            delete(record)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        } header: {
                            Text("今日记录")
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("今天")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AppPage1AddSheet()
            }
        }
    }

    private func addQuickRecord() {
        let record = AppDrinkRecord(id: UUID(), amount: 250, date: Date())
        store.records.append(record)
        store.save()
    }

    func delete(_ record: AppDrinkRecord) {
        withAnimation {
            store.records.removeAll { $0.id == record.id }
            store.save()
        }
    }
}

private struct AppPage1Row: View {
    let record: AppDrinkRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .foregroundStyle(Color.accentColor)
                .frame(width: 34, height: 34)
                .background(Color.accentColor.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("\(record.amount) 毫升")
                    .font(.headline)
                Text(AppPage1Format.timeString(for: record.date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("一杯")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct AppPage1Empty: View {
    let onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("今天还没喝水", systemImage: "drop")
        } description: {
            Text("点右上角或下方按钮，开始记录第一杯水")
        } actions: {
            Button("添加记录") {
                onAdd()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct AppPage1SummaryCard: View {
    let todayTotal: Int
    let goal: Int
    let progress: Double
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 18) {
                ZStack {
                    AppPage1ProgressRing(progress: progress)
                        .frame(width: 120, height: 120)

                    VStack(spacing: 0) {
                        Text("\(todayTotal)")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                        Text("毫升")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("今日目标")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(goal) 毫升")
                        .font(.title3.bold())

                    if todayTotal >= goal {
                        Text("已达标")
                            .font(.caption)
                            .foregroundStyle(Color.green)
                    } else {
                        Text("还差 \(goal - todayTotal) 毫升")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }

            Button(action: onAdd) {
                Label("快速加 250 毫升", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.gray.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AppPage1ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 14)

            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}

private struct AppPage1AddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    @State private var amount: Int = 250

    private var isAmountValid: Bool {
        amount > 0 && amount <= 5000
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $amount, in: 50...5000, step: 50) {
                        HStack {
                            Text("喝水量")
                            Spacer()
                            Text("\(amount) 毫升")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("记录一杯水")
                } footer: {
                    Text("也可以直接点主页的快速按钮加 250 毫升。")
                }
            }
            .navigationTitle("添加记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!isAmountValid)
                }
            }
        }
    }

    func save() {
        guard isAmountValid else { return }

        let record = AppDrinkRecord(id: UUID(), amount: amount, date: Date())
        store.records.append(record)
        store.save()
        dismiss()
    }
}

private enum AppPage1Format {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    static func timeString(for date: Date) -> String {
        timeFormatter.string(from: date)
    }
}