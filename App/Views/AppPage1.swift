import SwiftUI

struct AppPage1View: View {
    @EnvironmentObject var store: AppStore
    @State private var showingCustomAdd = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage1SummaryCard(store: store)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section {
                    if store.todayRecords.isEmpty {
                        AppPage1EmptyView(onAdd: { addRecord() })
                    } else {
                        ForEach(store.todayRecords) { record in
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
                    HStack {
                        Text("今日记录")
                        Spacer()
                        if !store.todayRecords.isEmpty {
                            Text("共 \(store.todayRecords.count) 条")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("今天")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCustomAdd = true
                    } label: {
                        Label("自定义", systemImage: "plus.circle")
                    }
                }
            }
            .sheet(isPresented: $showingCustomAdd) {
                AppPage1AddSheet()
            }
        }
    }

    func addRecord(amountML: Int = 250, note: String = "") {
        store.records.append(AppWaterRecord(id: UUID(), date: Date(), amountML: amountML, note: note))
        store.save()
    }

    func delete(_ record: AppWaterRecord) {
        store.records.removeAll { $0.id == record.id }
        store.save()
    }
}

struct AppPage1SummaryCard: View {
    @ObservedObject var store: AppStore

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日已喝")
                        .font(.headline)
                    Text("\(store.todayTotal) 毫升")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                }
                Spacer()
                AppPage1CircularProgress(progress: Double(store.todayTotal) / Double(max(store.dailyGoalML, 1)))
            }

            ProgressView(value: Double(store.todayTotal), total: Double(max(store.dailyGoalML, 1)))
                .tint(.blue)

            HStack {
                Label("目标 \(store.dailyGoalML) 毫升", systemImage: "target")
                Spacer()
                if let latest = store.latestRecordDate {
                    Label(latestTimeText(latest), systemImage: "clock")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Button {
                addRecord()
            } label: {
                Label("喝一杯 250 毫升", systemImage: "drop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func addRecord() {
        store.records.append(AppWaterRecord(id: UUID(), date: Date(), amountML: 250, note: ""))
        store.save()
    }

    private func latestTimeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct AppPage1CircularProgress: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(uiColor: .systemGray5), lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .bold()
                .foregroundStyle(.primary)
        }
        .frame(width: 56, height: 56)
    }
}

struct AppPage1Row: View {
    let record: AppWaterRecord

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("\(record.amountML) 毫升")
                    .font(.headline)
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(timeFormatter.string(from: record.date))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AppPage1EmptyView: View {
    let onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("今天还没有记录", systemImage: "drop")
        } description: {
            Text("点击下方按钮喝一杯 250 毫升")
        } actions: {
            Button("喝一杯 250 毫升", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
    }
}

struct AppPage1AddSheet: View {
    @ObservedObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = "250"
    @State private var note = ""
    @State private var showValidation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("毫升") {
                    TextField("毫升", text: $amountText)
                        .keyboardType(.numberPad)
                }
                Section("备注") {
                    TextField("可选", text: $note)
                }
                if showValidation {
                    Section {
                        Text("请输入 1 到 5000 之间的毫升数")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("添加记录")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let amount = Int(amountText), amount > 0, amount <= 5000 else {
                            showValidation = true
                            return
                        }
                        store.records.append(AppWaterRecord(id: UUID(), date: Date(), amountML: amount, note: note))
                        store.save()
                        dismiss()
                    }
                    .disabled(Int(amountText) == nil || (Int(amountText) ?? 0) <= 0)
                }
            }
        }
    }
}