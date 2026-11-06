import Foundation
import SwiftUI

struct AppPage2View: View {
    @EnvironmentObject private var store: AppMedicineStore

    @State private var name = ""
    @State private var specification = ""
    @State private var manufacturer = ""
    @State private var category = "未分类"
    @State private var location = ""
    @State private var quantity = 1
    @State private var unit = "盒"
    @State private var expiryDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var isOpened = false
    @State private var notes = ""
    @State private var showingSavedAlert = false

    private static let commonLocations = ["客厅药箱", "卧室床头柜", "厨房抽屉", "冰箱冷藏"]
    private static let units = ["盒", "瓶", "袋", "支", "板"]

    var availableCategories: [String] {
        var cats = store.categories
        if !cats.contains("未分类") {
            cats.append("未分类")
        }
        return cats
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedLocation: String {
        location.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        !trimmedName.isEmpty && !trimmedLocation.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("药名", text: $name)
                    TextField("规格", text: $specification)
                    TextField("生产厂家", text: $manufacturer)
                    Picker("分类", selection: $category) {
                        ForEach(availableCategories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                } header: {
                    Text("基本信息")
                } footer: {
                    Text("药名为必填项。")
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("例如：客厅药箱第一层", text: $location)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Self.commonLocations, id: \.self) { loc in
                                    AppPage2LocationChip(
                                        title: loc,
                                        isSelected: location == loc,
                                        action: { location = loc }
                                    )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    Stepper(value: $quantity, in: 1...999) {
                        HStack {
                            Text("数量")
                            Spacer()
                            Text("\(quantity) \(unit)")
                                .monospacedDigit()
                        }
                    }
                    Picker("单位", selection: $unit) {
                        ForEach(Self.units, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                } header: {
                    Text("存放与数量")
                } footer: {
                    Text("存放位置为必填项。")
                }

                Section {
                    DatePicker(
                        selection: $expiryDate,
                        displayedComponents: .date
                    ) {
                        Label("有效期至", systemImage: "calendar")
                    }
                    .environment(\.locale, Locale(identifier: "zh_CN"))

                    Toggle(isOn: $isOpened) {
                        Label("已开封", systemImage: "checkmark.circle")
                    }
                } header: {
                    Text("有效期与状态")
                }

                Section {
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("用法、注意事项等")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                    }
                } header: {
                    Text("备注")
                }

                Section {
                    if canSave {
                        AppPage2SummaryCard(
                            name: trimmedName,
                            specification: specification.trimmingCharacters(in: .whitespacesAndNewlines),
                            manufacturer: manufacturer.trimmingCharacters(in: .whitespacesAndNewlines),
                            category: category,
                            location: trimmedLocation,
                            quantity: quantity,
                            unit: unit,
                            expiryDate: expiryDate,
                            isOpened: isOpened,
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    } else {
                        AppPage2EmptyStateCard()
                    }
                } header: {
                    Text("预览")
                }

                Section {
                    Button(action: { saveMedicine() }) {
                        Label("存入药箱", systemImage: "tray.and.arrow.down.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!canSave)

                    Button(role: .destructive, action: { clearForm() }) {
                        Label("清空表单", systemImage: "arrow.counterclockwise")
                    }
                } footer: {
                    Text("添加后可在药品列表和临期提醒中查看。")
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("添加一盒药")
            .alert("已添加", isPresented: $showingSavedAlert) {
                Button("继续", role: .cancel) { }
            } message: {
                Text("这盒药已经放进药箱。")
            }
        }
    }

    private func saveMedicine() {
        let newMedicine = AppMedicine(
            id: UUID(),
            name: trimmedName,
            specification: specification.trimmingCharacters(in: .whitespacesAndNewlines),
            manufacturer: manufacturer.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            location: trimmedLocation,
            quantity: quantity,
            unit: unit,
            expiryDate: expiryDate,
            isOpened: isOpened,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date()
        )
        store.medicines.append(newMedicine)
        store.save()
        clearForm()
        showingSavedAlert = true
    }

    private func clearForm() {
        name = ""
        specification = ""
        manufacturer = ""
        location = ""
        quantity = 1
        unit = "盒"
        expiryDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
        isOpened = false
        notes = ""
        category = "未分类"
    }
}

private struct AppPage2LocationChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.accentColor.opacity(0.18) : Color.gray.opacity(0.10)
                )
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct AppPage2EmptyStateCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pills")
                .font(.title2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text("还没有预览")
                    .font(.subheadline.weight(.semibold))
                Text("填写药名和存放位置后，这里会显示这盒药的信息。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct AppPage2SummaryCard: View {
    let name: String
    let specification: String
    let manufacturer: String
    let category: String
    let location: String
    let quantity: Int
    let unit: String
    let expiryDate: Date
    let isOpened: Bool
    let notes: String

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                    Text(category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(quantity) \(unit)")
                    .font(.title3.monospacedDigit())
            }

            if !specification.isEmpty || !manufacturer.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    if !specification.isEmpty {
                        Text("规格：\(specification)")
                    }
                    if !manufacturer.isEmpty {
                        Text("厂家：\(manufacturer)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Divider()

            Label(location, systemImage: "location")
                .font(.subheadline)

            Label(Self.dateFormatter.string(from: expiryDate), systemImage: "calendar")
                .font(.subheadline)

            HStack {
                if isOpened {
                    Label("已开封", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.orange)
                } else {
                    Label("未开封", systemImage: "shippingbox")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .font(.caption)

            if !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}