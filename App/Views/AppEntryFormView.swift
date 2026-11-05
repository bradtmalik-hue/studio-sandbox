import SwiftUI
import Combine
import Foundation

struct AppEntryFormView: View {
    @EnvironmentObject private var store: AppGrowthStore

    @State private var date = Date()
    @State private var heightString = ""
    @State private var weightString = ""
    @State private var showSuccess = false
    @State private var successMessage = ""

    private var isFormValid: Bool {
        guard let height = Double(heightString), let weight = Double(weightString) else { return false }
        return height > 0 && weight > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                } header: {
                    Text("记录日期")
                }

                Section {
                    TextField("身高 (cm)", text: $heightString)
                        .keyboardType(.decimalPad)
                    TextField("体重 (kg)", text: $weightString)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("身高体重")
                } footer: {
                    Text("请输入正数，支持小数点后一位或两位。")
                }

                Section {
                    Button(action: saveRecord) {
                        Text("保存记录")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .disabled(!isFormValid)
                } footer: {
                    Text("保存后，成长曲线会自动更新。")
                }

                Section {
                    if store.records.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "figure.child")
                                .font(.system(size: 44))
                                .foregroundColor(.green)
                            Text("还没有成长记录")
                                .font(.headline)
                            Text("从第一笔开始，见证孩子的成长")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        ForEach(Array(store.records.prefix(3))) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "ruler")
                                            .foregroundColor(.green)
                                        Text("\(record.height, specifier: "%.1f") cm")
                                    }
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Image(systemName: "scalemass")
                                            .foregroundColor(.green)
                                        Text("\(record.weight, specifier: "%.1f") kg")
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Text("最近记录")
                }
            }
            .navigationTitle("记一笔")
            .alert("保存成功", isPresented: $showSuccess) {
                Button("好", role: .cancel) { }
            } message: {
                Text(successMessage)
            }
        }
    }

    private func saveRecord() {
        guard let height = Double(heightString), let weight = Double(weightString) else { return }
        let record = AppGrowthRecord(date: date, height: height, weight: weight)
        store.add(record)

        let dateText = date.formatted(date: .abbreviated, time: .omitted)
        successMessage = "\(dateText) 的身高 \(String(format: "%.1f", height)) cm、体重 \(String(format: "%.1f", weight)) kg 已保存。"
        showSuccess = true

        heightString = ""
        weightString = ""
    }
}