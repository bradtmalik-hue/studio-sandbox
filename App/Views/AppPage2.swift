import SwiftUI
import Combine

struct AppPage2View: View {
    @EnvironmentObject var store: AppFishingStore
    @State private var searchText = ""
    @State private var filterMode = 0
    @State private var showingAddSheet = false

    var filteredRecords: [AppCatchRecord] {
        let sorted = store.records.sorted { $0.date > $1.date }
        let filtered = sorted.filter { record in
            let matchesSearch = searchText.isEmpty ||
                record.species.localizedCaseInsensitiveContains(searchText) ||
                record.spot.localizedCaseInsensitiveContains(searchText) ||
                record.method.localizedCaseInsensitiveContains(searchText)
            let matchesFilter: Bool
            switch filterMode {
            case 0: matchesFilter = true
            case 1: matchesFilter = record.isReleased
            case 2: matchesFilter = !record.isReleased
            default: matchesFilter = true
            }
            return matchesSearch && matchesFilter
        }
        return filtered
    }

    private var summaryText: String {
        let total = filteredRecords.count
        let totalWeight = filteredRecords.reduce(0.0) { $0 + $1.weightKg }
        if let latest = filteredRecords.first {
            return "共\(total)条 · 合计\(String(format: "%.2f", totalWeight))kg · 最近 \(Self.chineseDateFormatter.string(from: latest.date))"
        } else {
            return "暂无收获记录"
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage2SummaryCard(text: summaryText)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section {
                    Picker("筛选", selection: $filterMode) {
                        Text("全部").tag(0)
                        Text("已放流").tag(1)
                        Text("已带走").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                if filteredRecords.isEmpty {
                    ContentUnavailableView {
                        Label("没有收获记录", systemImage: "fish")
                    } description: {
                        Text("去记一笔，记录你的第一条鱼获")
                    } actions: {
                        Button("添加第一条") {
                            showingAddSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .padding(.bottom, 96)
                } else {
                    ForEach(filteredRecords) { record in
                        NavigationLink {
                            AppPage2DetailView(record: record)
                        } label: {
                            AppPage2Row(record: record)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                delete(record)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                    Section {
                        Color.clear.frame(height: 96)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .searchable(text: $searchText, prompt: "搜索鱼种、钓点、钓法")
            .navigationTitle("收获记录")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AppPage2AddSheet { newRecord in
                    store.records.append(newRecord)
                    store.save()
                }
            }
        }
    }

    func delete(_ record: AppCatchRecord) {
        if let index = store.records.firstIndex(where: { $0.id == record.id }) {
            store.records.remove(at: index)
            store.save()
        }
    }

    static let chineseDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 HH:mm"
        return f
    }()
}

struct AppPage2SummaryCard: View {
    let text: String

    var body: some View {
        HStack {
            Image(systemName: "tray.full.fill")
                .foregroundColor(AppTheme.accent)
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text("收获概览")
                    .font(AppTheme.fontSection)
                    .foregroundColor(AppTheme.text)
                Text(text)
                    .font(AppTheme.fontCaption)
                    .foregroundColor(AppTheme.dim)
            }
            Spacer()
        }
        .padding(AppTheme.s4)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal, AppTheme.s4)
        .padding(.vertical, AppTheme.s2)
    }
}

struct AppPage2Row: View {
    let record: AppCatchRecord

    var body: some View {
        HStack(spacing: AppTheme.s3) {
            Image(systemName: record.isReleased ? "arrow.uturn.backward.circle.fill" : "fish.fill")
                .foregroundColor(record.isReleased ? .green : .blue)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(AppTheme.accentSoft.opacity(0.2))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(record.species)
                    .font(AppTheme.fontBody)
                    .foregroundColor(AppTheme.text)
                    .lineLimit(1)
                HStack(spacing: 12) {
                    Label(record.spot, systemImage: "mappin.circle")
                    Label(String(format: "%.2f kg", record.weightKg), systemImage: "scalemass")
                }
                .font(AppTheme.fontCaption)
                .foregroundColor(AppTheme.dim)
                .lineLimit(1)

                HStack(spacing: 12) {
                    Text("\(record.lengthCm, specifier: "%.1f") cm")
                    Text(Self.chineseDateFormatter.string(from: record.date))
                    Text(record.method)
                }
                .font(AppTheme.fontLabel)
                .foregroundColor(AppTheme.text.opacity(0.8))
                .lineLimit(1)
            }
            Spacer()
            AppPage2Badge(text: record.isReleased ? "放流" : "带走", color: record.isReleased ? .green : .orange)
        }
        .padding(.vertical, AppTheme.s2)
    }

    static let chineseDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日"
        return f
    }()
}

struct AppPage2Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(AppTheme.fontCaption)
            .foregroundColor(color)
            .padding(.horizontal, AppTheme.s2)
            .padding(.vertical, AppTheme.s1)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

struct AppPage2DetailView: View {
    @EnvironmentObject var store: AppFishingStore
    @Environment(\.dismiss) var dismiss
    let record: AppCatchRecord

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: record.isReleased ? "arrow.uturn.backward.circle.fill" : "fish.fill")
                            .font(.system(size: 50))
                            .foregroundColor(record.isReleased ? .green : .blue)
                        Text(record.species)
                            .font(AppTheme.fontTitle)
                        Text(record.isReleased ? "已放流" : "已带走")
                            .font(AppTheme.fontLabel)
                            .foregroundColor(record.isReleased ? .green : .orange)
                    }
                    Spacer()
                }
                .padding(.vertical, AppTheme.s4)
            }
            .listRowBackground(Color.clear)

            Section("基本信息") {
                AppPage2DetailRow(label: "重量", value: String(format: "%.2f kg", record.weightKg))
                AppPage2DetailRow(label: "长度", value: String(format: "%.1f cm", record.lengthCm))
                AppPage2DetailRow(label: "钓点", value: record.spot)
                AppPage2DetailRow(label: "钓法", value: record.method)
            }

            Section("时间与备注") {
                AppPage2DetailRow(label: "时间", value: Self.dateFormatter.string(from: record.date))
                if !record.note.isEmpty {
                    AppPage2DetailRow(label: "备注", value: record.note)
                }
            }

            Section {
                Button("删除这条记录", role: .destructive) {
                    if let index = store.records.firstIndex(where: { $0.id == record.id }) {
                        store.records.remove(at: index)
                        store.save()
                    }
                    dismiss()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("收获详情")
        .navigationBarTitleDisplayMode(.inline)
    }

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年M月d日 HH:mm"
        return f
    }()
}

struct AppPage2DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.fontBody)
                .foregroundColor(AppTheme.dim)
            Spacer()
            Text(value)
                .font(AppTheme.fontBody)
                .foregroundColor(AppTheme.text)
        }
    }
}

struct AppPage2AddSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var species = ""
    @State private var weightKg = ""
    @State private var lengthCm = ""
    @State private var spot = ""
    @State private var method = ""
    @State private var note = ""
    @State private var isReleased = false
    @State private var date = Date()
    @State private var showingValidationError = false

    let onSave: (AppCatchRecord) -> Void

    var isFormValid: Bool {
        !species.isEmpty &&
        Double(weightKg) != nil && (Double(weightKg) ?? 0) > 0 &&
        Double(lengthCm) != nil && (Double(lengthCm) ?? 0) > 0 &&
        !spot.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("鱼种信息") {
                    TextField("鱼种（如 鲤鱼）", text: $species)
                    TextField("重量（kg）", text: $weightKg)
                        .keyboardType(.decimalPad)
                    TextField("长度（cm）", text: $lengthCm)
                        .keyboardType(.decimalPad)
                }

                Section("钓获详情") {
                    TextField("钓点", text: $spot)
                    TextField("钓法（如 台钓）", text: $method)
                    TextField("备注（可选）", text: $note)
                    DatePicker("时间", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Toggle("已放流", isOn: $isReleased)
                }

                if showingValidationError {
                    Text("请填写鱼种、重量、长度和钓点，且数值需大于0")
                        .font(AppTheme.fontCaption)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("添加收获")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard isFormValid, let w = Double(weightKg), let l = Double(lengthCm) else {
                            showingValidationError = true
                            return
                        }
                        let newRecord = AppCatchRecord(id: UUID(), species: species, weightKg: w, lengthCm: l, date: date, spot: spot, method: method, note: note, isReleased: isReleased)
                        onSave(newRecord)
                        dismiss()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
}