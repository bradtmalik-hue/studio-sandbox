import SwiftUI
import Combine
import Foundation

// 药箱列表页面
struct AppMedicineListView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingAddSheet = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if store.medicines.isEmpty {
                    ContentUnavailableView(
                        "药箱是空的",
                        systemImage: "pills",
                        description: Text("点击右上角 + 添加药品，开始管理有效期和存放位置")
                    )
                } else {
                    List {
                        ForEach(filteredMedicines) { medicine in
                            AppMedicineRow(medicine: medicine)
                        }
                        .onDelete(perform: deleteMedicines)
                    }
                    .searchable(text: $searchText, prompt: "搜索药品名称或位置")
                }
            }
            .navigationTitle("药箱")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("添加药品")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AppAddMedicineView()
                    .environmentObject(store)
            }
        }
    }
    
    private var filteredMedicines: [AppMedicine] {
        if searchText.isEmpty {
            return sortedMedicines
        } else {
            return sortedMedicines.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.storageSpot.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var sortedMedicines: [AppMedicine] {
        store.medicines.sorted { $0.expiryDate < $1.expiryDate }
    }
    
    private func deleteMedicines(at offsets: IndexSet) {
        let idsToDelete = offsets.map { filteredMedicines[$0].id }
        store.medicines.removeAll { idsToDelete.contains($0.id) }
    }
}

// 药品行视图
struct AppMedicineRow: View {
    let medicine: AppMedicine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(medicine.name)
                    .font(.headline)
                Spacer()
                Text(medicine.expiryDate, format: .dateTime.year().month().day())
                    .font(.subheadline)
                    .foregroundStyle(expiryColor)
            }
            HStack {
                Label(medicine.storageSpot, systemImage: "location")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if isExpiringSoon {
                    Text("快过期")
                        .font(.caption2)
                        .padding(4)
                        .background(Color.orange.opacity(0.2), in: Capsule())
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private var isExpiringSoon: Bool {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: medicine.expiryDate).day ?? 0
        return days >= 0 && days <= 30
    }
    
    private var expiryColor: Color {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: medicine.expiryDate).day ?? 0
        if days < 0 { return .red }
        if days <= 30 { return .orange }
        return .primary
    }
}

// 加药页面
struct AppAddMedicineView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var expiryDate = Date()
    @State private var storageSpot = ""
    @State private var notes = ""
    @State private var reminderDaysBefore: Int = 7
    
    private let reminderOptions = [0, 3, 7, 14, 30]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("药品信息") {
                    TextField("药品名称", text: $name)
                    DatePicker("有效期至", selection: $expiryDate, displayedComponents: .date)
                    TextField("存放位置", text: $storageSpot)
                }
                
                Section("备注") {
                    TextField("备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("提醒") {
                    Picker("提前提醒", selection: $reminderDaysBefore) {
                        ForEach(reminderOptions, id: \.self) { days in
                            if days == 0 {
                                Text("不提醒").tag(days)
                            } else {
                                Text("提前 \(days) 天").tag(days)
                            }
                        }
                    }
                }
            }
            .navigationTitle("添加药品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        addMedicine()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func addMedicine() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedLocation = storageSpot.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
        let medicine = AppMedicine(
            name: trimmedName,
            expiryDate: expiryDate,
            storageSpot: trimmedLocation.isEmpty ? "未指定" : trimmedLocation,
            notes: trimmedNotes,
            reminderDays: reminderDaysBefore
        )
        store.medicines.append(medicine)
        dismiss()
    }
}

// 提醒设置页面
struct AppReminderSettingsView: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("启用过期提醒", isOn: $store.reminderSettings.expiryRemindersEnabled)
                    if store.reminderSettings.expiryRemindersEnabled {
                        Picker("默认提前天数", selection: $store.reminderSettings.defaultReminderDays) {
                            ForEach([3, 7, 14, 30], id: \.self) { days in
                                Text("提前 \(days) 天").tag(days)
                            }
                        }
                    }
                } header: {
                    Text("提醒")
                } footer: {
                    Text("当药品接近有效期时，App 会提醒你。需要系统通知权限才能接收提醒。")
                }
                
                Section("关于") {
                    LabeledContent("应用名称", value: "Home MedBox")
                    LabeledContent("版本", value: "1.0")
                }
            }
            .navigationTitle("提醒设置")
        }
    }
}

#Preview {
    AppMedicineListView()
        .environmentObject(AppStore())
}