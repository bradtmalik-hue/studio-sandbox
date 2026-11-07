import SwiftUI
import Foundation
import Combine

class AppWaterStore: ObservableObject {
    @Published var records: [AppWaterRecord] = [] {
        didSet {
            save()
        }
    }

    var todayRecords: [AppWaterRecord] {
        records.filter { Calendar.current.isDateInToday($0.date) }
    }

    var todayTotal: Double {
        todayRecords.reduce(0) { $0 + $1.amount }
    }

    func save() {
        // 可在此实现持久化存储
    }
}

struct AppPage1View: View {
    let store: AppWaterStore
    let dailyGoal: Double

    @State private var showAddSheet = false

    init(store: AppWaterStore, dailyGoal: Double) {
        self.store = store
        self.dailyGoal = dailyGoal
        self._showAddSheet = State(initialValue: false)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    Section {
                        AppPage1RingCard(
                            total: store.todayTotal,
                            goal: dailyGoal,
                            count: store.todayRecords.count,
                            latestTime: latestTimeText,
                            addAction: { amount in
                                addWater(amount)
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                    }

                    Section("今日记录") {
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
                }
                .contentMargins(.bottom, 96, for: .scrollContent)

                if store.todayRecords.isEmpty {
                    ContentUnavailableView {
                        Label("今天还没喝水", systemImage: "drop.circle")
                    } description: {
                        Text("点击下方按钮，快速记录 250 毫升")
                    } actions: {
                        Button("添加第一条") {
                            addWater(250)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("今天")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AppPage1AddSheet()
                    .environmentObject(store)
            }
        }
    }

    private var latestTimeText: String {
        guard let latest = store.todayRecords.max(by: { $0.date < $1.date }) else {
            return "暂无记录"
        }
        return Self.timeFormatter.string(from: latest.date)
    }

    private func addWater(_ amount: Double) {
        let record = AppWaterRecord(id: UUID(), date: Date(), amount: amount, note: nil)
        store.records = store.records + [record]
        store.save()
    }

    func delete(_ record: AppWaterRecord) {
        store.records = store.records.filter { $0.id != record.id }
        store.save()
    }
}

private struct AppPage1RingCard: View {
    let total: Double
    let goal: Double
    let count: Int
    let latestTime: String
    let addAction: (Double) -> Void

    private var progress: Double {
        min(total / goal, 1.0)
    }

    private var progressColor: Color {
        progress >= 1.0 ? .green : .teal
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .foregroundStyle(progressColor)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 4) {
                        Text("\(Int(total))")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                        Text("毫升")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 140, height: 140)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(.teal)
                        Text("今日目标 \(Int(goal)) 毫升")
                            .font(.subheadline)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Text("最近 \(latestTime)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(.secondary)
                        Text("共 \(count) 条")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button {
                addAction(250)
            } label: {
                Label("加 250 毫升", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
        }
        .padding(20)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct AppPage1Row: View {
    let record: AppWaterRecord
    let timeText: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .font(.title2)
                .foregroundStyle(.teal)
                .frame(width: 36, height: 36)
                .background(Color.teal.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(record.amount)) 毫升")
                    .font(.headline)
                Text(timeText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("单次饮水")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

private struct AppPage1AddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppWaterStore
    @State private var amountText: String = ""

    var amount: Double? {
        Double(amountText)
    }

    private var isAmountValid: Bool {
        guard let amount = amount else { return false }
        return amount >= 50 && amount <= 2000
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("喝水量") {
                    TextField("例如 250", text: $amountText)
                        .keyboardType(.numberPad)
                    if let amount = amount, !isAmountValid {
                        Text("请输入 50–2000 毫升")
                            .foregroundStyle(.red)
                    }
                }

                Section("快速选择") {
                    HStack {
                        ForEach([250.0, 500.0, 1000.0], id: \.self) { preset in
                            Button("\(Int(preset))") {
                                amountText = "\(Int(preset))"
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .navigationTitle("添加喝水")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let amount = amount, isAmountValid else { return }
                        let record = AppWaterRecord(id: UUID(), date: Date(), amount: amount, note: nil)
                        store.records = store.records + [record]
                        store.save()
                        dismiss()
                    }
                    .disabled(!isAmountValid)
                }
            }
        }
    }
}