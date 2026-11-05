import SwiftUI
import Foundation

struct AppEntryFormView: View {
    @EnvironmentObject private var store: AppGrowthStore
    @Environment(\.dismiss) private var dismiss

    private enum Field: Hashable {
        case height
        case weight
    }

    private let record: AppGrowthRecord?

    @State private var date: Date
    @State private var heightText: String
    @State private var weightText: String
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: Field?

    init(record: AppGrowthRecord? = nil) {
        self.record = record
        _date = State(initialValue: record?.date ?? Date())
        _heightText = State(initialValue: record.map { String(format: "%.1f", $0.heightCM) } ?? "")
        _weightText = State(initialValue: record.map { String(format: "%.2f", $0.weightKG) } ?? "")
    }

    var body: some View {
        Form {
            Section("日期") {
                DatePicker(
                    "测量日期",
                    selection: $date,
                    displayedComponents: .date
                )
            }

            Section("身高体重") {
                HStack {
                    Text("身高")
                    Spacer()
                    TextField("厘米", text: $heightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .height)
                    Text("cm")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("体重")
                    Spacer()
                    TextField("公斤", text: $weightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .weight)
                    Text("kg")
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("请填写孩子最新的身高和体重。")
            }
        }
        .navigationTitle(record == nil ? "记一笔" : "编辑记录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    save()
                }
            }
        }
        .alert("无法保存", isPresented: $showError) {
            Button("好", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .preferredColorScheme(.light)
    }

    private func save() {
        let normalizedHeight = heightText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        let normalizedWeight = weightText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard let height = Double(normalizedHeight), height > 0,
              let weight = Double(normalizedWeight), weight > 0 else {
            errorMessage = "请输入有效的身高（厘米）和体重（公斤）。"
            showError = true
            return
        }

        if let record {
            let updatedRecord = AppGrowthRecord(
                id: record.id,
                date: date,
                heightCM: height,
                weightKG: weight
            )
            store.update(updatedRecord)
        } else {
            let newRecord = AppGrowthRecord(
                date: date,
                heightCM: height,
                weightKG: weight
            )
            store.add(newRecord)
        }

        dismiss()
    }
}

typealias EntryFormView = AppEntryFormView