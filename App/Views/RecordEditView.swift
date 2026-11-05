import SwiftUI
import Foundation

struct AppRecordEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppGrowthStore

    let record: AppGrowthRecord
    @State private var date: Date
    @State private var heightText: String
    @State private var weightText: String
    @State private var showDeleteConfirm = false

    init(record: AppGrowthRecord) {
        self.record = record
        _date = State(initialValue: record.date)
        _heightText = State(initialValue: String(format: "%.1f", record.heightCm))
        _weightText = State(initialValue: String(format: "%.2f", record.weightKg))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("日期") {
                    DatePicker("记录日期", selection: $date, displayedComponents: .date)
                }

                Section("测量数据") {
                    TextField("身高（厘米）", text: $heightText)
                        .keyboardType(.decimalPad)
                    TextField("体重（公斤）", text: $weightText)
                        .keyboardType(.decimalPad)
                }

                if let message = validationMessage {
                    Section {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button("保存修改") {
                        save()
                    }
                    .disabled(!canSave)
                }

                Section {
                    Button("删除这条记录", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .confirmationDialog(
                "确定要删除这条记录吗？",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("删除记录", role: .destructive) {
                    deleteRecord()
                }
                Button("保留", role: .cancel) {}
            }
        }
    }

    private var heightValue: Double? {
        Double(heightText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
    }

    private var weightValue: Double? {
        Double(weightText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
    }

    private var canSave: Bool {
        guard let h = heightValue, let w = weightValue else { return false }
        return h > 0 && w > 0
    }

    private var validationMessage: String? {
        let trimmedHeight = heightText.trimmingCharacters(in: .whitespaces)
        let trimmedWeight = weightText.trimmingCharacters(in: .whitespaces)

        if trimmedHeight.isEmpty || trimmedWeight.isEmpty {
            return "请填写身高和体重。"
        }
        if heightValue == nil || weightValue == nil {
            return "身高和体重必须是数字。"
        }
        if !canSave {
            return "身高和体重必须大于 0。"
        }
        return nil
    }

    private func save() {
        guard let h = heightValue, let w = weightValue, canSave else { return }
        let updated = AppGrowthRecord(id: record.id, date: date, heightCm: h, weightKg: w)
        store.update(updated)
        dismiss()
    }

    private func deleteRecord() {
        store.delete(record)
        dismiss()
    }
}