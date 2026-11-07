import SwiftUI
import Foundation

private let AppPage2Categories = ["感冒用药", "退烧止痛", "肠胃用药", "外用药品", "慢性病用药", "维生素", "其他"]
private let AppPage2Units = ["盒", "瓶", "袋", "片", "支"]

struct AppPage2View: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var category: String = "感冒用药"
    @State private var expiryDate: Date = Calendar.current.date(byAdding: .day, value: 365, to: Date()) ?? Date()
    @State private var storageLocation: String = ""
    @State private var quantity: Int = 1
    @State private var unit: String = "盒"
    @State private var reminderEnabled: Bool = true
    @State private var notes: String = ""
    @State private var errorMessage: String = ""
    @State private var showDiscardAlert: Bool = false

    private let defaultExpiryDate: Date = Calendar.current.date(byAdding: .day, value: 365, to: Date()) ?? Date()

    private var isDirty: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !storageLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !notes.isEmpty ||
        quantity != 1 ||
        reminderEnabled != true ||
        category != AppPage2Categories[0] ||
        expiryDate != defaultExpiryDate
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedLocation: String {
        storageLocation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && !trimmedLocation.isEmpty && expiryDate > Date()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AppPage2SectionCard(title: "药品信息", icon: "pills.fill") {
                        AppPage2FieldRow(label: "药名", icon: "textformat") {
                            TextField("例如：布洛芬缓释胶囊", text: $name)
                                .multilineTextAlignment(.trailing)
                        }
                        AppPage2FieldRow(label: "分类", icon: "tag") {
                            Picker("分类", selection: $category) {
                                ForEach(AppPage2Categories, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                    }

                    AppPage2SectionCard(title: "有效期与数量", icon: "calendar.badge.clock") {
                        DatePicker("有效期至", selection: $expiryDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "zh_CN"))
                        AppPage2FieldRow(label: "数量", icon: "number") {
                            Stepper("\(quantity) \(unit)", value: $quantity, in: 1...999)
                                .fixedSize()
                        }
                        AppPage2FieldRow(label: "单位", icon: "shippingbox") {
                            Picker("单位", selection: $unit) {
                                ForEach(AppPage2Units, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                    }

                    AppPage2SectionCard(title: "存放位置与提醒", icon: "location.fill") {
                        AppPage2FieldRow(label: "存放位置", icon: "cabinet.fill") {
                            TextField("例如：客厅药箱第二层", text: $storageLocation)
                                .multilineTextAlignment(.trailing)
                        }
                        Toggle(isOn: $reminderEnabled) {
                            Label("到期前提醒", systemImage: "bell.badge.fill")
                        }
                    }

                    AppPage2SectionCard(title: "备注", icon: "note.text") {
                        TextField("可选，例如：饭后服用", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                    }

                    if !errorMessage.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.callout)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("添加一盒药")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if isDirty {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .alert("放弃更改？", isPresented: $showDiscardAlert) {
                Button("继续编辑", role: .cancel) { }
                Button("放弃更改", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("你有未保存的修改，确定要离开吗？")
            }
            .interactiveDismissDisabled(isDirty)
        }
    }

    func save() {
        guard !trimmedName.isEmpty else {
            errorMessage = "请填写药名"
            return
        }
        guard !trimmedLocation.isEmpty else {
            errorMessage = "请填写存放位置"
            return
        }
        guard expiryDate > Date() else {
            errorMessage = "有效期必须晚于今天"
            return
        }

        let newMedicine = AppMedicineBox(
            id: UUID(),
            name: trimmedName,
            category: category,
            expiryDate: expiryDate,
            storageLocation: trimmedLocation,
            quantity: quantity,
            unit: unit,
            reminderEnabled: reminderEnabled,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date()
        )
        store.add(newMedicine)
        dismiss()
    }
}

private struct AppPage2SectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct AppPage2FieldRow<Content: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let content: Content

    init(label: String, icon: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(label)
                .foregroundColor(.secondary)
            Spacer(minLength: 8)
            content
        }
        .padding(.vertical, 4)
    }
}