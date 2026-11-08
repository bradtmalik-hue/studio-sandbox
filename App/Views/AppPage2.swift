import SwiftUI
import Foundation

struct AppPage2View: View {
    @EnvironmentObject private var store: AppInventoryStore
    @Environment(\.dismiss) private var dismiss

    let item: AppPetSupplyItem?

    @State private var name = ""
    @State private var quantityText = ""
    @State private var unit = "袋"
    @State private var expirationDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var category = "猫粮"
    @State private var notes = ""
    @State private var showSaveConfirmation = false

    private let units = ["袋", "罐", "盒", "包", "瓶", "支", "片"]
    private let categories = ["猫粮", "狗粮", "零食", "药品", "清洁", "玩具", "其它"]

    init(item: AppPetSupplyItem? = nil) {
        self.item = item
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("名称（必填）", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                } header: {
                    Text("基本信息")
                } footer: {
                    if name.trimmingCharacters(in: .whitespaces).isEmpty {
                        AppPage2ValidationText(text: "请输入物品名称")
                    }
                }

                Section {
                    HStack {
                        Text("数量")
                        Spacer()
                        TextField("0", text: $quantityText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }
                    if isQuantityInvalid {
                        AppPage2ValidationText(text: "数量必须大于 0")
                    }
                    Picker("单位", selection: $unit) {
                        ForEach(units, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                } header: {
                    Text("数量与单位")
                }

                Section {
                    Picker("分类", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                } header: {
                    Text("分类")
                }

                Section {
                    DatePicker("过期日期", selection: $expirationDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                } header: {
                    Text("保质期")
                }

                Section {
                    TextField("备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Text("备注")
                }

                Section {
                    AppPage2SaveButton(isEnabled: isFormValid) {
                        save()
                    }
                } footer: {
                    if !isFormValid {
                        Text("请填写必填项，并确保数量有效")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(item == nil ? "新增物品" : "编辑物品")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("已保存", isPresented: $showSaveConfirmation) {
                Button("好", role: .cancel) { }
            } message: {
                Text("物品信息已保存。")
            }
            .onAppear(perform: populateIfEditing)
        }
    }

    private var parsedQuantity: Double? {
        Double(quantityText)
    }

    private var isQuantityInvalid: Bool {
        !quantityText.isEmpty && (parsedQuantity == nil || parsedQuantity! <= 0)
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !isQuantityInvalid && parsedQuantity != nil && parsedQuantity! > 0
    }

    private func populateIfEditing() {
        guard let item = item else { return }
        name = item.name
        quantityText = String(item.quantity)
        unit = item.unit
        expirationDate = item.expirationDate
        category = item.category
        notes = item.notes
    }

    func save() {
        guard isFormValid, let quantity = parsedQuantity else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let newItem = AppPetSupplyItem(
            id: item?.id ?? UUID(),
            name: trimmedName,
            quantity: quantity,
            unit: unit,
            expirationDate: expirationDate,
            category: category,
            notes: notes
        )

        if let index = store.items.firstIndex(where: { $0.id == newItem.id }) {
            store.items[index] = newItem
        } else {
            store.items.append(newItem)
        }

        store.save()
        showSaveConfirmation = true
        dismiss()
    }
}

private struct AppPage2ValidationText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.red)
    }
}

private struct AppPage2SaveButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("保存")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!isEnabled)
    }
}