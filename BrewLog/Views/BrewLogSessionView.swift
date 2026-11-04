import SwiftUI
import Combine
import Foundation

struct BrewLogSessionView: View {
    @EnvironmentObject private var store: BrewLogStore

    @State private var selectedBeanIndex: Int = 0
    @State private var ratioText: String = "15.0"
    @State private var tempText: String = "92.0"
    @State private var secondsText: String = "180"
    @State private var date: Date = Date()
    @State private var showSaveAlert = false
    @State private var saveMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("咖啡豆") {
                    if store.beans.isEmpty {
                        Text("请先在豆单页面添加咖啡豆")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("选择豆子", selection: $selectedBeanIndex) {
                            ForEach(store.beans.indices, id: \.self) { index in
                                VStack(alignment: .leading) {
                                    Text(store.beans[index].roaster)
                                    if !store.beans[index].notes.isEmpty {
                                        Text(store.beans[index].notes)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .tag(index)
                            }
                        }
                    }
                }

                Section("冲煮参数") {
                    TextField("粉水比 (水:粉)", text: $ratioText)
                        .keyboardType(.decimalPad)
                    TextField("水温 (°C)", text: $tempText)
                        .keyboardType(.decimalPad)
                    TextField("时间 (秒)", text: $secondsText)
                        .keyboardType(.numberPad)
                    DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section {
                    Button("保存本次冲煮") {
                        saveSession()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(store.beans.isEmpty)
                }
            }
            .navigationTitle("冲一杯")
            .tint(.orange)
            .alert(saveMessage, isPresented: $showSaveAlert) {
                Button("好", role: .cancel) { }
            }
            .onAppear {
                if selectedBeanIndex >= store.beans.count {
                    selectedBeanIndex = 0
                }
            }
        }
    }

    private func saveSession() {
        guard store.beans.indices.contains(selectedBeanIndex) else {
            saveMessage = "请先在豆单页面添加咖啡豆"
            showSaveAlert = true
            return
        }

        let bean = store.beans[selectedBeanIndex]
        let ratio = Double(ratioText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let temp = Double(tempText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let seconds = Int(secondsText) ?? 0

        guard ratio > 0, temp > 0, seconds > 0 else {
            saveMessage = "请填写有效的冲煮参数"
            showSaveAlert = true
            return
        }

        let session = BrewLogSession(bean: bean, ratio: ratio, temp: temp, seconds: seconds, date: date)
        store.addSession(session)

        saveMessage = "已保存本次手冲记录"
        showSaveAlert = true
    }
}