import SwiftUI
import Foundation

enum AppPage1ContainerFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case water = "水"
    case coffee = "咖啡"
    case tea = "茶"
    var id: String { rawValue }
}

struct AppPage1View: View {
    @EnvironmentObject private var store: AppHydrationStore
    @State private var filter: AppPage1ContainerFilter = .all
    @State private var selectedRecord: AppWaterRecord?
    @State private var showAddedFeedback = false

    private let goal: Double = 2000

    var filteredRecords: [AppWaterRecord] {
        let today = store.todayRecords
        switch filter {
        case .all:
            return today
        case .water:
            return today.filter { $0.container.localizedCaseInsensitiveContains("水") }
        case .coffee:
            return today.filter { $0.container.localizedCaseInsensitiveContains("咖啡") }
        case .tea:
            return today.filter { $0.container.localizedCaseInsensitiveContains("茶") }
        }
    }

    private var latestTimeText: String {
        guard let latest = store.todayRecords.max(by: { $0.date < $1.date }) else { return "--" }
        return Self.timeFormatter.string(from: latest.date)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppPage1HeroCard(
                    todayTotal: store.todayTotal,
                    remaining: store.remainingToday,
                    goal: goal,
                    onAdd: { addWater(250) }
                )
                .padding(.horizontal)
                .padding(.top, 8)

                if showAddedFeedback {
                    Text("已添加 250 ml")
                        .font(.footnote)
                        .foregroundStyle(.teal)
                        .transition(.opacity)
                        .padding(.top, 4)
                }

                Picker("筛选", selection: $filter) {
                    ForEach(AppPage1ContainerFilter.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                if filteredRecords.isEmpty {
                    Spacer()
                    AppPage1EmptyView(onAdd: { addWater(250) })
                    Spacer()
                } else {
                    List {
                        Section {
                            HStack {
                                Text("共 \(filteredRecords.count) 条")
                                Spacer()
                                Text("合计 \(Int(store.todayTotal)) ml")
                                Spacer()
                                Text("最近 \(latestTimeText)")
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color.clear)
                        }

                        Section {
                            ForEach(filteredRecords) { record in
                                Button {
                                    selectedRecord = record
                                } label: {
                                    AppPage1Row(record: record)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        delete(record)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("今天")
            .sheet(item: $selectedRecord) { record in
                AppPage1EditView(record: record)
                    .environmentObject(store)
            }
        }
    }

    private func addWater(_ amount: Double) {
        let newRecord = AppWaterRecord(id: UUID())
        withAnimation {
            store.records.append(newRecord)
            store.save()
            showAddedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showAddedFeedback = false
            }
        }
    }

    func delete(_ record: AppWaterRecord) {
        withAnimation {
            store.records.removeAll { $0.id == record.id }
            store.save()
        }
    }
}

struct AppPage1HeroCard: View {
    let todayTotal: Double
    let remaining: Double
    let goal: Double
    let onAdd: () -> Void

    private var progress: Double {
        min(todayTotal / goal, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("距离目标还差")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(Int(max(remaining, 0))) ml")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.teal)
                    Text("目标 \(Int(goal)) ml · 已喝 \(Int(todayTotal)) ml")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image("sample1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .opacity(0.95)
            }

            ProgressView(value: progress)
                .tint(.teal)
                .scaleEffect(y: 1.6, anchor: .center)

            Button(action: onAdd) {
                Label("一键加 250 ml", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
        )
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
            Image(systemName: "drop.circle.fill")
                .font(.title2)
                .foregroundStyle(.teal)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.container.isEmpty ? "喝水" : record.container)
                    .font(.headline)
                Text(record.note.isEmpty ? "饮用水" : record.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(timeFormatter.string(from: record.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(record.amount, specifier: "%.0f") ml")
                .font(.subheadline)
                .bold()
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
}

struct AppPage1EmptyView: View {
    let onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("今天还没喝水", systemImage: "drop.degreesign")
        } description: {
            Text("点击下面按钮，记录你的第一杯水")
        } actions: {
            Button("添加第一条") {
                onAdd()
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
        }
    }
}

struct AppPage1EditView: View {
    @EnvironmentObject private var store: AppHydrationStore
    @Environment(\.dismiss) private var dismiss

    let record: AppWaterRecord

    @State private var container: String = ""
    @State private var amount: Double = 250
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var selectedContainer = "水杯"
    @State private var hasChanges = false
    @State private var showCancelConfirm = false

    private let containerOptions = ["水杯", "咖啡", "茶", "自定义"]

    private var isFormValid: Bool {
        !container.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0 && amount <= 3000
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("饮水时间") {
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                    DatePicker("时间", selection: $date, displayedComponents: .hourAndMinute)
                }

                Section("饮水内容") {
                    Picker("容器", selection: $selectedContainer) {
                        ForEach(containerOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)

                    if selectedContainer == "自定义" {
                        TextField("输入容器名称", text: $container)
                    } else {
                        Text(container)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("饮水量")
                        Spacer()
                        TextField("0", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 88)
                        Text("ml")
                            .foregroundStyle(.secondary)
                    }

                    TextField("备注（可选）", text: $note)
                }

                Section {
                    if !container.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0 && amount <= 3000 {
                        EmptyView()
                    } else {
                        if container.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text("请选择或输入容器名称")
                                .foregroundStyle(.red)
                        }
                        if amount <= 0 {
                            Text("饮水量必须大于 0")
                                .foregroundStyle(.red)
                        } else if amount > 3000 {
                            Text("单次饮水量不能超过 3000 ml")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if hasChanges {
                            showCancelConfirm = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!isFormValid)
                }
            }
            .confirmationDialog("未保存的更改", isPresented: $showCancelConfirm) {
                Button("放弃更改", role: .destructive) {
                    dismiss()
                }
                Button("继续编辑", role: .cancel) {}
            } message: {
                Text("确定要放弃刚才的修改吗？")
            }
            .interactiveDismissDisabled(hasChanges)
            .onAppear {
                container = record.container
                amount = record.amount
                note = record.note
                date = record.date
                if containerOptions.contains(record.container) {
                    selectedContainer = record.container
                } else {
                    selectedContainer = "自定义"
                }
            }
            .onChange(of: container) { _, _ in hasChanges = true }
            .onChange(of: amount) { _, _ in hasChanges = true }
            .onChange(of: note) { _, _ in hasChanges = true }
            .onChange(of: date) { _, _ in hasChanges = true }
            .onChange(of: selectedContainer) { _, newValue in
                if newValue != "自定义" {
                    container = newValue
                } else {
                    container = ""
                }
                hasChanges = true
            }
        }
    }

    func save() {
        let updated = AppWaterRecord(id: record.id)
        if let index = store.records.firstIndex(where: { $0.id == record.id }) {
            store.records[index] = updated
        } else {
            store.records.append(updated)
        }
        store.save()
        dismiss()
    }
}