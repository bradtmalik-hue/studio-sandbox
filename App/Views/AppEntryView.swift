import SwiftUI

struct AppEntryView: View {
    @EnvironmentObject private var store: AppGrowthStore

    @State private var date = Date()
    @State private var height: Double = 100
    @State private var weight: Double = 20
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false

    private let heightRange: ClosedRange<Double> = 40...250
    private let weightRange: ClosedRange<Double> = 1...200

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("随手记下身高体重，曲线自己长出来", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .padding(.vertical, 4)
                }
                .listRowBackground(Color.blue.opacity(0.08))

                Section {
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                } header: {
                    Text("记录日期")
                }

                Section {
                    TextField("身高", value: $height, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("体重", value: $weight, format: .number)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("身体测量")
                } footer: {
                    Text("身高范围：\(Int(heightRange.lowerBound))-\(Int(heightRange.upperBound)) 厘米；体重范围：\(Int(weightRange.lowerBound))-\(Int(weightRange.upperBound)) 公斤")
                }

                Section {
                    Button {
                        saveRecord()
                    } label: {
                        Label("保存记录", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!isValid)
                } footer: {
                    Text("保存后会立即出现在成长曲线与历史记录中。")
                }
            }
            .navigationTitle("记一笔")
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("好", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var isValid: Bool {
        heightRange.contains(height) && weightRange.contains(weight)
    }

    private func saveRecord() {
        guard isValid else {
            alertTitle = "输入有误"
            alertMessage = "请输入有效的身高和体重。"
            showingAlert = true
            return
        }

        let record = AppGrowthRecord(
            heightCm: height,
            weightKg: weight,
            date: date,
            id: UUID()
        )

        store.addRecord(record)

        alertTitle = "已保存"
        alertMessage = "这条成长记录已经保存。"
        showingAlert = true
    }
}