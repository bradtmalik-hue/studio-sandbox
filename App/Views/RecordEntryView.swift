import SwiftUI
import Combine

struct AppRecordEntryView: View {
    @EnvironmentObject var store: AppGrowthStore

    @State private var date: Date = Date()
    @State private var heightText: String = ""
    @State private var weightText: String = ""
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }
                Section("生长数据") {
                    TextField("身高 (cm)", text: $heightText)
                        .keyboardType(.decimalPad)
                    TextField("体重 (kg)", text: $weightText)
                        .keyboardType(.decimalPad)
                }
                Section {
                    Button(action: saveRecord) {
                        Text("保存")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(heightText.isEmpty || weightText.isEmpty)
                }
            }
            .navigationTitle("记一笔")
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("好")))
            }
        }
    }

    private func saveRecord() {
        let trimmedHeight = heightText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedWeight = weightText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let height = Double(trimmedHeight), let weight = Double(trimmedWeight) else {
            alertTitle = "输入无效"
            alertMessage = "请输入有效的数字。"
            showingAlert = true
            return
        }

        guard height > 0, weight > 0 else {
            alertTitle = "输入无效"
            alertMessage = "身高和体重必须大于零。"
            showingAlert = true
            return
        }

        guard height >= 30, height <= 250 else {
            alertTitle = "身高超出范围"
            alertMessage = "请输入 30 - 250 厘米之间的身高。"
            showingAlert = true
            return
        }

        guard weight >= 1, weight <= 200 else {
            alertTitle = "体重超出范围"
            alertMessage = "请输入 1 - 200 公斤之间的体重。"
            showingAlert = true
            return
        }

        let record = AppGrowthRecord(date: date, heightCm: height, weightKg: weight)
        store.add(record)

        heightText = ""
        weightText = ""
        date = Date()

        alertTitle = "保存成功"
        alertMessage = "记录已保存。"
        showingAlert = true
    }
}