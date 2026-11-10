import SwiftUI
import Combine

struct AppPage1View: View {
    @EnvironmentObject var store: AppFishingStore

    @State private var species: String = ""
    @State private var weightText: String = ""
    @State private var lengthText: String = ""
    @State private var date: Date = Date()
    @State private var spot: String = ""
    @State private var method: String = "手竿"
    @State private var note: String = ""
    @State private var isReleased: Bool = false
    @State private var searchText: String = ""
    @State private var showValidationAlert: Bool = false
    @State private var editingRecord: AppCatchRecord?
    @State private var isEditing: Bool = false

    private let methods = ["手竿", "海竿", "路亚", "飞钓", "矶钓"]

    var filteredRecords: [AppCatchRecord] {
        let sorted = store.records.sorted { $0.date > $1.date }
        if searchText.isEmpty {
            return sorted
        } else {
            return sorted.filter {
                $0.species.localizedCaseInsensitiveContains(searchText) ||
                $0.spot.localizedCaseInsensitiveContains(searchText) ||
                $0.method.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private var doubleFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }

    var isFormValid: Bool {
        !species.trimmingCharacters(in: .whitespaces).isEmpty &&
        !spot.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0 &&
        (Double(lengthText.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    Section {
                        AppCard {
                            VStack(alignment: .leading, spacing: AppTheme.spacing.s4) {
                                HStack(spacing: AppTheme.spacing.s2) {
                                    Image(systemName: "fish.fill")
                                        .foregroundColor(AppTheme.colors.accent)
                                    Text("快速记一笔")
                                        .font(AppTheme.fontSection)
                                        .foregroundColor(AppTheme.colors.text)
                                }

                                VStack(spacing: AppTheme.spacing.s3) {
                                    HStack(spacing: AppTheme.spacing.s3) {
                                        Text("鱼种")
                                            .font(AppTheme.fontLabel)
                                            .foregroundColor(AppTheme.colors.dim)
                                            .frame(width: 52, alignment: .leading)
                                        TextField("例如：鲫鱼", text: $species)
                                            .textFieldStyle(.roundedBorder)
                                            .font(AppTheme.fontBody)
                                    }

                                    HStack(spacing: AppTheme.spacing.s3) {
                                        Text("重量")
                                            .font(AppTheme.fontLabel)
                                            .foregroundColor(AppTheme.colors.dim)
                                            .frame(width: 52, alignment: .leading)
                                        TextField("例如：1.25", text: $weightText)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(.roundedBorder)
                                            .font(AppTheme.fontBody)
                                        Text("kg")
                                            .font(AppTheme.fontLabel)
                                            .foregroundColor(AppTheme.colors.dim)
                                    }

                                    HStack(spacing: AppTheme.spacing.s3) {
                                        Text("长度")
                                            .font(AppTheme.fontLabel)
                                            .foregroundColor(AppTheme.colors.dim)
                                            .frame(width: 52, alignment: .leading)
                                        TextField("例如：32", text: $lengthText)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.roundedBorder)
                                            .font(AppTheme.fontBody)
                                        Text("cm")
                                            .font(AppTheme.fontLabel)
                                            .foregroundColor(AppTheme.colors.dim)
                                    }

                                    DatePicker(selection: $date, displayedComponents: [.date, .hourAndMinute]) {
                                        Text("时间")
                                            .font(AppTheme.fontLabel)
                                            .foregroundColor(AppTheme.colors.dim)
                                    }

                                    HStack(spacing: AppTheme.spacing.s3) {
                                        Text("钓点")
                                            .font(AppTheme.fontLabel)
                                            .foregroundColor(AppTheme.colors.dim)
                                            .frame(width: 52, alignment: .leading)
                                        TextField("例如：南湖", text: $spot)
                                            .textFieldStyle(.roundedBorder)
                                            .font(AppTheme.fontBody)
                                    }

                                    Picker(selection: $method, label: Text("钓法").font(AppTheme.fontLabel).foregroundColor(AppTheme.colors.dim)) {
                                        ForEach(methods, id: \.self) { m in
                                            Text(m).tag(m)
                                        }
                                    }
                                    .pickerStyle(.menu)

                                    Toggle(isOn: $isReleased) {
                                        Text("已放流")
                                            .font(AppTheme.fontLabel)
                                            .foregroundColor(AppTheme.colors.dim)
                                    }

                                    VStack(alignment: .leading, spacing: AppTheme.spacing.s2) {
                                        Text("备注")
                                            .font(AppTheme.fontLabel)
                                            .foregroundColor(AppTheme.colors.dim)
                                        TextField("补充说明（可选）", text: $note, axis: .vertical)
                                            .lineLimit(3...6)
                                            .textFieldStyle(.roundedBorder)
                                            .font(AppTheme.fontBody)
                                    }

                                    AppPrimaryButton(title: "保存记录", action: saveRecord)
                                        .disabled(!isFormValid)
                                        .opacity(isFormValid ? 1.0 : 0.5)
                                }
                            }
                            .padding(AppTheme.spacing.s4)
                        }
                        .id("formSection")
                    }

                    if store.records.isEmpty {
                        Section {
                            ContentUnavailableView {
                                Label("还没有收获记录", systemImage: "fish")
                            } description: {
                                Text("钓到第一条鱼后，点击下方按钮记下来")
                            } actions: {
                                Button("去记一笔") {
                                    withAnimation {
                                        proxy.scrollTo("formSection", anchor: .top)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(AppTheme.colors.accent)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.spacing.s8)
                        }
                    } else {
                        Section {
                            ForEach(filteredRecords) { record in
                                Button {
                                    startEditing(record)
                                } label: {
                                    AppPage1RecordRow(record: record)
                                }
                                .buttonStyle(.plain)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        delete(record)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                    Button {
                                        startEditing(record)
                                    } label: {
                                        Label("编辑", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                        } header: {
                            Text("最近收获")
                                .font(AppTheme.fontSection)
                                .foregroundColor(AppTheme.colors.text)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("记一笔")
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索鱼种、钓点或钓法")
                .contentMargins(.bottom, 96, for: .scrollContent)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            clearForm()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                    }
                }
                .sheet(isPresented: $isEditing, onDismiss: {
                    editingRecord = nil
                }) {
                    if let record = editingRecord {
                        NavigationStack {
                            AppPage1EditForm(record: record, onSave: "") { updated in
                                update(updated)
                                isEditing = false
                            }
                            .navigationTitle("编辑记录")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("取消") {
                                        isEditing = false
                                    }
                                }
                            }
                        }
                    }
                }
                .alert("请检查输入", isPresented: $showValidationAlert) {
                    Button("好", role: .cancel) { }
                } message: {
                    Text("鱼种、钓点不能为空，重量和长度必须大于0。")
                }
            }
        }
        .environment(\.locale, Locale(identifier: "zh_CN"))
    }

    private func saveRecord() {
        guard isFormValid else {
            showValidationAlert = true
            return
        }
        guard let weight = Double(weightText.replacingOccurrences(of: ",", with: ".")),
              let length = Double(lengthText.replacingOccurrences(of: ",", with: ".")) else {
            showValidationAlert = true
            return
        }
        let record = AppCatchRecord(id: UUID(), species: species.trimmingCharacters(in: .whitespaces), weightKg: weight, lengthCm: length, date: date, spot: spot.trimmingCharacters(in: .whitespaces), method: method, note: note.trimmingCharacters(in: .whitespaces), isReleased: isReleased)
        store.add(record)
        clearForm()
    }

    func delete(_ record: AppCatchRecord) {
        store.delete(record)
    }

    func update(_ record: AppCatchRecord) {
        store.update(record)
    }

    private func clearForm() {
        species = ""
        weightText = ""
        lengthText = ""
        date = Date()
        spot = ""
        method = methods.first ?? "手竿"
        note = ""
        isReleased = false
    }

    private func startEditing(_ record: AppCatchRecord) {
        editingRecord = record
        isEditing = true
    }
}

struct AppPage1RecordRow: View {
    let record: AppCatchRecord

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.spacing.s3) {
            VStack(alignment: .leading, spacing: AppTheme.spacing.s2) {
                Text(record.species)
                    .font(AppTheme.fontBody)
                    .foregroundColor(AppTheme.colors.text)
                HStack(spacing: AppTheme.spacing.s2) {
                    Text(record.spot)
                        .font(AppTheme.fontLabel)
                        .foregroundColor(AppTheme.colors.dim)
                    Text(record.method)
                        .font(AppTheme.fontLabel)
                        .foregroundColor(AppTheme.colors.dim)
                }
                Text(formattedDate(record.date))
                    .font(AppTheme.fontCaption)
                    .foregroundColor(AppTheme.colors.dim)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f", record.weightKg))
                    .font(AppTheme.fontNumber)
                    .foregroundColor(AppTheme.colors.accent)
                Text("kg")
                    .font(AppTheme.fontCaption)
                    .foregroundColor(AppTheme.colors.dim)
                if record.isReleased {
                    AppBadge(text: "已放流")
                }
            }
        }
        .padding(.vertical, AppTheme.spacing.s2)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

struct AppPage1EditForm: View {
    let record: AppCatchRecord
    let onSave: (AppCatchRecord) -> Void

    @State private var species: String
    @State private var weightText: String
    @State private var lengthText: String
    @State private var date: Date
    @State private var spot: String
    @State private var method: String
    @State private var note: String
    @State private var isReleased: Bool
    @State private var showValidationAlert: Bool = false

    private let methods = ["手竿", "海竿", "路亚", "飞钓", "矶钓"]

    init(record: AppCatchRecord, onSave: @escaping (AppCatchRecord) -> Void) {
        self.record = record
        self.onSave = onSave
        _species = State(initialValue: record.species)
        _weightText = State(initialValue: String(format: "%.2f", record.weightKg))
        _lengthText = State(initialValue: String(format: "%.0f", record.lengthCm))
        _date = State(initialValue: record.date)
        _spot = State(initialValue: record.spot)
        _method = State(initialValue: record.method)
        _note = State(initialValue: record.note)
        _isReleased = State(initialValue: record.isReleased)
    }

    private var isValid: Bool {
        !species.trimmingCharacters(in: .whitespaces).isEmpty &&
        !spot.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0 &&
        (Double(lengthText.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }

    var body: some View {
        Form {
            Section {
                TextField("鱼种", text: $species)
                    .font(AppTheme.fontBody)
                TextField("钓点", text: $spot)
                    .font(AppTheme.fontBody)
                TextField("重量 (kg)", text: $weightText)
                    .keyboardType(.decimalPad)
                    .font(AppTheme.fontBody)
                TextField("长度 (cm)", text: $lengthText)
                    .keyboardType(.numberPad)
                    .font(AppTheme.fontBody)
                Picker("钓法", selection: $method) {
                    ForEach(methods, id: \.self) { m in
                        Text(m).tag(m)
                    }
                }
                DatePicker("时间", selection: $date, displayedComponents: [.date, .hourAndMinute])
                Toggle("已放流", isOn: $isReleased)
                TextField("备注", text: $note, axis: .vertical)
                    .lineLimit(3...6)
                    .font(AppTheme.fontBody)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    save()
                }
                .disabled(!isValid)
                .opacity(isValid ? 1.0 : 0.5)
            }
        }
        .alert("请检查输入", isPresented: $showValidationAlert) {
            Button("好", role: .cancel) { }
        } message: {
            Text("鱼种、钓点不能为空，重量和长度必须大于0。")
        }
    }

    func save() {
        guard isValid else {
            showValidationAlert = true
            return
        }
        guard let weight = Double(weightText.replacingOccurrences(of: ",", with: ".")),
              let length = Double(lengthText.replacingOccurrences(of: ",", with: ".")) else {
            showValidationAlert = true
            return
        }
        let updated = AppCatchRecord(id: record.id, species: species.trimmingCharacters(in: .whitespaces), weightKg: weight, lengthCm: length, date: date, spot: spot.trimmingCharacters(in: .whitespaces), method: method, note: note.trimmingCharacters(in: .whitespaces), isReleased: isReleased)
        onSave(updated)
    }
}