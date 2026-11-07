import SwiftUI
import Foundation

private let AppPage1DateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M月d日 HH:mm"
    return formatter
}()

private func AppPage1FormattedDate(_ date: Date) -> String {
    AppPage1DateFormatter.string(from: date)
}

struct AppPage1View: View {
    @EnvironmentObject var store: AppStore
    @State private var filterNotesOnly = false
    @State private var showingCustomAdd = false
    @State private var selectedEntry: AppWaterEntry?

    private var filteredTodayEntries: [AppWaterEntry] {
        let entries = store.todayEntries.sorted { $0.date > $1.date }
        if filterNotesOnly {
            return entries.filter { !$0.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
        return entries
    }

    private var lastTodayEntryDate: Date? {
        store.todayEntries.max(by: { $0.date < $1.date })?.date
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage1SummaryCard(
                        totalML: store.totalToday,
                        goalML: store.dailyGoalML,
                        entryCount: store.todayEntries.count,
                        lastDate: lastTodayEntryDate
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section {
                    Picker("筛选", selection: $filterNotesOnly) {
                        Text("全部").tag(false)
                        Text("有备注").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }

                Section("今日记录") {
                    if filteredTodayEntries.isEmpty {
                        AppPage1EmptyView(onAdd: {
                            showingCustomAdd = true
                        })
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(filteredTodayEntries) { entry in
                            Button {
                                selectedEntry = entry
                            } label: {
                                AppPage1Row(
                                    entry: entry,
                                    goalML: store.dailyGoalML,
                                    timeText: AppPage1FormattedDate(entry.date)
                                )
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.delete(entry)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
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
            .safeAreaInset(edge: .bottom) {
                AppPage1QuickAddBar(totalToday: store.totalToday, goalML: store.dailyGoalML, onAdd: {
                    store.add(AppWaterEntry(id: UUID(), amountML: 250, date: Date(), note: ""))
                })
            }
            .sheet(item: $selectedEntry) { entry in
                AppPage1DetailView(entry: entry)
            }
            .sheet(isPresented: $showingCustomAdd) {
                AppPage1CustomAddView()
            }
        }
    }
}

struct AppPage1SummaryCard: View {
    let totalML: Int
    let goalML: Int
    let entryCount: Int
    let lastDate: Date?

    private var progress: Double {
        guard goalML > 0 else { return 0 }
        return min(Double(totalML) / Double(goalML), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("今日喝水", systemImage: "drop.circle.fill")
                    .font(.headline)
                Spacer()
                Text("\(entryCount) 次")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(totalML)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text("毫升")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
                if let lastDate {
                    VStack(alignment: .trailing) {
                        Text("最近一次")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(AppPage1FormattedDate(lastDate))
                            .font(.subheadline)
                    }
                }
            }

            ProgressView(value: progress)
                .tint(.blue)

            HStack {
                Text("目标 \(goalML) 毫升")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
        .padding(.vertical, 4)
    }
}

struct AppPage1Row: View {
    let entry: AppWaterEntry
    let goalML: Int
    let timeText: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
                .background(Color.blue.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.amountML) 毫升")
                    .font(.headline)
                Text(timeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.note.isEmpty ? "无备注" : entry.note)
                    .font(.caption)
                    .foregroundStyle(entry.note.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                if goalML > 0 {
                    Text("\(Int(Double(entry.amountML) / Double(goalML) * 100))% 目标")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AppPage1EmptyView: View {
    let onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("今天还没记录喝水", systemImage: "drop")
        } description: {
            Text("点击下方按钮快速添加 250 毫升")
        } actions: {
            Button("添加第一条", action: onAdd)
                .buttonStyle(.bordered)
        }
    }
}

struct AppPage1QuickAddBar: View {
    let totalToday: Int
    let goalML: Int
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("今日 \(totalToday) / \(goalML) 毫升")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Button(action: onAdd) {
                Label("加 250 毫升", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding(12)
        .background(.ultraThinMaterial)
    }
}

struct AppPage1DetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore
    let entry: AppWaterEntry

    var body: some View {
        NavigationStack {
            List {
                Section("数量") {
                    Label("\(entry.amountML) 毫升", systemImage: "drop.fill")
                }
                Section("时间") {
                    Label(AppPage1FormattedDate(entry.date), systemImage: "clock")
                }
                Section("备注") {
                    Text(entry.note.isEmpty ? "无备注" : entry.note)
                }
                Section {
                    Button(role: .destructive) {
                        store.delete(entry)
                        dismiss()
                    } label: {
                        Label("删除记录", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("记录详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

struct AppPage1CustomAddView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = "250"
    @State private var note = ""
    @State private var useCurrentTime = true
    @State private var customDate = Date()

    private var amountValue: Int {
        Int(amountText) ?? 0
    }

    private var isValid: Bool {
        amountValue > 0 && amountValue <= 5000
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("喝水量") {
                    TextField("毫升", text: $amountText)
                        .keyboardType(.numberPad)
                    if !isValid {
                        Text("请输入 1 到 5000 之间的毫升数")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("时间") {
                    Toggle("使用当前时间", isOn: $useCurrentTime)
                    if !useCurrentTime {
                        DatePicker(
                            "选择时间",
                            selection: $customDate,
                            in: Date().addingTimeInterval(-7 * 86400)...Date(),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                    }
                }

                Section("备注") {
                    TextField("例如：晨起一杯", text: $note)
                }
            }
            .navigationTitle("添加喝水记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let date = useCurrentTime ? Date() : customDate
                        store.add(
                            AppWaterEntry(
                                id: UUID(),
                                amountML: amountValue,
                                date: date,
                                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                        )
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}