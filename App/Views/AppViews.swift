import SwiftUI
import Combine

// MARK: - 药箱列表页
struct AppMedicationListView: View {
    @EnvironmentObject var store: AppModels
    @State private var showAddMedication = false

    private var sortedMedications: [AppMedication] {
        store.medications.sorted { med1, med2 in
            med1.expirationDate < med2.expirationDate
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.medications.isEmpty {
                    ContentUnavailableView(
                        "药箱空空的",
                        systemImage: "pills",
                        description: Text("点击右上角添加药品，记录有效期和存放位置")
                    )
                } else {
                    List {
                        ForEach(sortedMedications) { med in
                            AppMedicationRowView(medication: med)
                        }
                        .onDelete(perform: store.deleteMedication)
                    }
                }
            }
            .navigationTitle("药箱")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddMedication = true
                    } label: {
                        Label("添加药品", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddMedication) {
                AppAddMedicationView()
                    .environmentObject(store)
            }
        }
    }
}

// MARK: - 药品行视图
struct AppMedicationRowView: View {
    let medication: AppMedication
    @EnvironmentObject var store: AppModels

    private var daysUntilExpiry: Int? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: medication.expirationDate)
        return calendar.dateComponents([.day], from: start, to: end).day
    }

    private var isExpired: Bool {
        guard let days = daysUntilExpiry else { return false }
        return days < 0
    }

    private var isExpiringSoon: Bool {
        guard let days = daysUntilExpiry, !isExpired else { return false }
        return days <= store.reminderDays
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isExpired ? "exclamationmark.octagon.fill" : (isExpiringSoon ? "clock.fill" : "pills.fill"))
                .foregroundStyle(isExpired ? .red : (isExpiringSoon ? .orange : .gray))
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(medication.expirationDate, format: .dateTime.year().month().day())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Image(systemName: "location")
                        .font(.caption)
                    Text(medication.location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let days = daysUntilExpiry, days <= store.reminderDays {
                    Text(days < 0 ? "已过期 \(abs(days)) 天" : "\(days) 天后过期")
                        .font(.caption)
                        .foregroundStyle(days < 0 ? .red : .orange)
                        .fontWeight(.semibold)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("数量: \(medication.quantity)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !medication.notes.isEmpty {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 添加药品页
struct AppAddMedicationView: View {
    @EnvironmentObject var store: AppModels
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var expirationDate = Date().addingTimeInterval(60 * 60 * 24 * 90)
    @State private var location = ""
    @State private var quantity = 1
    @State private var notes = ""

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("药品信息") {
                    TextField("药品名称", text: $name)
                    DatePicker(
                        "有效期至",
                        selection: $expirationDate,
                        displayedComponents: .date
                    )
                }

                Section("存放位置") {
                    Picker("位置", selection: $location) {
                        ForEach(store.locations, id: \.self) { loc in
                            Text(loc).tag(loc)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("数量与备注") {
                    Stepper(value: $quantity, in: 1...999) {
                        HStack {
                            Text("数量")
                            Spacer()
                            Text("\(quantity)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    TextField("备注（选填）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("添加药品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let med = AppMedication(
                            id: UUID(),
                            name: trimmedName,
                            expirationDate: expirationDate,
                            location: location.isEmpty ? (store.locations.first ?? "药箱") : location,
                            quantity: quantity,
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                            addedDate: Date()
                        )
                        store.addMedication(med)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if location.isEmpty, let first = store.locations.first {
                    location = first
                }
            }
        }
    }
}

// MARK: - 提醒设置页
struct AppReminderSettingsView: View {
    @EnvironmentObject var store: AppModels

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("启用临期提醒", isOn: $store.reminderEnabled)
                    if store.reminderEnabled {
                        Stepper(value: $store.reminderDays, in: 1...180, step: 1) {
                            HStack {
                                Text("提前提醒天数")
                                Spacer()
                                Text("\(store.reminderDays) 天")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("提醒设置")
                } footer: {
                    Text("当药品有效期剩余天数不超过设定值时，会在药箱列表中高亮提醒。")
                }

                Section("关于临期提醒") {
                    Label("查看药箱列表时，临期药品会显示橙色钟表图标", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label("已过期药品会显示红色警告图标", systemImage: "exclamationmark.octagon.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("提醒")
        }
    }
}