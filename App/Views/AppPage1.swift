import SwiftUI
import Foundation

struct AppDrinkRecord: Identifiable, Codable {
    let id: UUID
    var date: Date
    var amount: Int
}

class AppStore: ObservableObject {
    @Published var records: [AppDrinkRecord] = []

    var todayRecords: [AppDrinkRecord] {
        records.filter { Calendar.current.isDateInToday($0.date) }
    }

    func save() {
    }
}

private let page1TimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "HH:mm"
    return formatter
}()

struct AppPage1View: View {
    @EnvironmentObject var store: AppStore
    @State private var showCustomAdd = false

    private var todayTotal: Int {
        store.todayRecords.reduce(0) { $0 + $1.amount }
    }

    private var sortedTodayRecords: [AppDrinkRecord] {
        store.todayRecords.sorted { $0.date > $1.date }
    }

    private var lastRecord: AppDrinkRecord? {
        sortedTodayRecords.first
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage1ProgressCard(
                        amount: todayTotal,
                        recordCount: store.todayRecords.count,
                        lastTime: lastRecord?.date,
                        onAdd: { addRecord(amount: 250) }
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section {
                    if store.todayRecords.isEmpty {
                        EmptyView()
                    } else {
                        ForEach(sortedTodayRecords) { record in
                            AppPage1Row(record: record)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        delete(record)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                } header: {
                    Text("今日记录")
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.bottom, 96, for: .scrollContent)
            .overlay {
                if store.todayRecords.isEmpty {
                    AppPage1EmptyState(onAdd: { addRecord(amount: 250) })
                        .padding(.horizontal, 24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("今天")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCustomAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showCustomAdd) {
                AppPage1CustomAddSheet()
                    .environmentObject(store)
            }
        }
    }

    private func addRecord(amount: Int) {
        let newRecord = AppDrinkRecord()
        store.records.append(newRecord)
        store.save()
    }

    func delete(_ record: AppDrinkRecord) {
        store.records.removeAll { $0.id == record.id }
        store.save()
    }
}

struct AppPage1ProgressCard: View {
    let amount: Int
    let recordCount: Int
    let lastTime: Date?
    let onAdd: () -> Void

    private let goal: Double = 2000

    private var progress: Double {
        min(Double(amount) / goal, 1.0)
    }

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.18), style: StrokeStyle(lineWidth: 20))
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.teal, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: progress)
                VStack(spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("\(amount) / 2000 毫升")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 220, height: 220)

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("已记录 \(recordCount) 次")
                        .font(.headline)
                    if let lastTime {
                        Text("最近 \(page1TimeFormatter.string(from: lastTime))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("今天还没有记录")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button(action: onAdd) {
                    Label("加 250 毫升", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.teal, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
    }
}

struct AppPage1Row: View {
    let record: AppDrinkRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .font(.title3)
                .foregroundStyle(.teal)
                .frame(width: 36, height: 36)
                .background(.teal.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("补充水分")
                    .font(.headline)
                Text(page1TimeFormatter.string(from: record.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(record.amount) 毫升")
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .padding(.vertical, 6)
    }
}

struct AppPage1EmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("今天还没有喝水", systemImage: "drop.fill")
        } description: {
            Text("点击按钮记一笔 250 毫升，开始今天的补水计划")
        } actions: {
            Button(action: onAdd) {
                Text("加 250 毫升")
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
        }
    }
}

struct AppPage1CustomAddSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: AppStore
    @State private var amountText = "250"
    @State private var showValidationAlert = false
    @FocusState private var amountFocused: Bool

    private var parsedAmount: Int? {
        Int(amountText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("毫升数", text: $amountText)
                        .keyboardType(.numberPad)
                        .focused($amountFocused)
                } header: {
                    Text("喝水记录")
                } footer: {
                    if let amount = parsedAmount, amount > 2000 {
                        Text("毫升数不能超过 2000")
                            .foregroundStyle(.red)
                    } else {
                        Text("建议每次 100–500 毫升")
                    }
                }
            }
            .navigationTitle("记一笔喝水")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let amount = parsedAmount, amount > 0 else {
                            return
                        }
                        if amount > 2000 {
                            showValidationAlert = true
                        } else {
                            let newRecord = AppDrinkRecord()
                            store.records.append(newRecord)
                            store.save()
                            dismiss()
                        }
                    }
                    .disabled(parsedAmount == nil || (parsedAmount ?? 0) <= 0)
                }
            }
            .alert("请输入有效毫升数", isPresented: $showValidationAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text("每次喝水 1–2000 毫升，请重新输入")
            }
            .onAppear {
                amountFocused = true
            }
        }
    }
}