import Foundation
import SwiftUI

struct AppEditRecordView: View {
    @EnvironmentObject private var store: AppGrowthStore
    @Environment(\.dismiss) private var dismiss

    let record: AppGrowthRecord

    @State private var date: Date
    @State private var heightText: String
    @State private var weightText: String
    @State private var validationMessage = ""
    @State private var showValidationAlert = false
    @State private var showDeleteConfirmation = false

    init(record: AppGrowthRecord) {
        self.record = record
        _date = State(initialValue: record.date)
        _heightText = State(initialValue: Self.formatHeight(record.heightCm))
        _weightText = State(initialValue: Self.formatWeight(record.weightKg))
    }

    var body: some View {
        Form {
            Section("日期") {
                DatePicker("记录日期", selection: $date, displayedComponents: .date)
            }

            Section("身高") {
                HStack {
                    Text("身高")
                    Spacer()
                    TextField("厘米", text: $heightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                }
            }

            Section("体重") {
                HStack {
                    Text("体重")
                    Spacer()
                    TextField("公斤", text: $weightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                }
            }

            Section {
                Button("保存修改") {
                    saveChanges()
                }
                .font(.headline)

                Button("删除这条记录", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
        .navigationTitle("编辑成长记录")
        .navigationBarTitleDisplayMode(.inline)
        .alert("请检查输入", isPresented: $showValidationAlert) {
            Button("好", role: .cancel) { }
        } message: {
            Text(validationMessage)
        }
        .confirmationDialog("确定删除这条记录吗？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("删除记录", role: .destructive) {
                deleteRecord()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("删除后无法恢复。")
        }
    }

    private static func formatHeight(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private static func formatWeight(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private func saveChanges() {
        guard date <= Date() else {
            validationMessage = "记录日期不能晚于今天。"
            showValidationAlert = true
            return
        }

        let heightTextNormalized = heightText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let height = Double(heightTextNormalized), height >= 20, height <= 250 else {
            validationMessage = "请输入合理的身高（20-250 厘米）。"
            showValidationAlert = true
            return
        }

        let weightTextNormalized = weightText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let weight = Double(weightTextNormalized), weight >= 0.5, weight <= 200 else {
            validationMessage = "请输入合理的体重（0.5-200 公斤）。"
            showValidationAlert = true
            return
        }

        let updated = AppGrowthRecord(
            heightCm: height,
            weightKg: weight,
            date: date,
            id: record.id
        )
        store.update(updated)
        dismiss()
    }

    private func deleteRecord() {
        store.delete(record)
        dismiss()
    }
}