import SwiftUI
import Foundation
import Combine

struct AppBrewLogView: View {
    @EnvironmentObject private var beanStore: AppBeanStore
    @EnvironmentObject private var brewStore: AppBrewStore

    @State private var selectedBeanID: UUID?
    @State private var dose: Double = 15.0
    @State private var water: Double = 240.0
    @State private var temperature: Double = 92.0
    @State private var duration: TimeInterval = 150.0
    @State private var isBest: Bool = false

    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showingAlert: Bool = false

    private var selectedBean: AppBean? {
        guard let id = selectedBeanID else { return nil }
        return beanStore.beans.first { $0.id == id }
    }

    private var isValidInput: Bool {
        dose > 0 && water > 0 && temperature > 0 && duration > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                if beanStore.beans.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "还没有豆子",
                            systemImage: "bag",
                            description: Text("请先到豆子库添加一包咖啡豆，再回来记录冲煮。")
                        )
                    }
                } else {
                    Section("豆子") {
                        Picker("选择豆子", selection: $selectedBeanID) {
                            ForEach(beanStore.beans) { bean in
                                Text(bean.name).tag(bean.id as UUID?)
                            }
                        }

                        if let bean = selectedBean {
                            HStack {
                                Text("剩余")
                                Spacer()
                                Text("\(bean.remainingGrams, specifier: "%.0f") g")
                                    .foregroundStyle(.secondary)
                            }

                            let days = daysSinceRoast(for: bean)
                            HStack {
                                Text("烘焙后")
                                Spacer()
                                Text("\(days) 天")
                                    .foregroundStyle(.secondary)
                                if days <= 14 {
                                    Text("新鲜")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.15))
                                        .foregroundStyle(.green)
                                        .clipShape(Capsule())
                                } else {
                                    Text("已放置")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.15))
                                        .foregroundStyle(.orange)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    Section("冲煮参数") {
                        HStack {
                            Text("粉量 (g)")
                            Spacer()
                            TextField("粉量", value: $dose, format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }

                        HStack {
                            Text("水量 (g)")
                            Spacer()
                            TextField("水量", value: $water, format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }

                        HStack {
                            Text("水温 (°C)")
                            Spacer()
                            TextField("水温", value: $temperature, format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }

                        HStack {
                            Text("总时长 (秒)")
                            Spacer()
                            TextField("总时长", value: $duration, format: .number.precision(.fractionLength(0)))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                    }

                    Section {
                        Toggle("标记为最佳一杯", isOn: $isBest)
                    }

                    Section {
                        Button {
                            saveRecord()
                        } label: {
                            Text("保存冲煮记录")
                                .frame(maxWidth: .infinity)
                                .bold()
                        }
                        .disabled(selectedBeanID == nil || !isValidInput)
                    }
                }
            }
            .navigationTitle("冲煮记录")
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("好"))
                )
            }
            .onAppear {
                if selectedBeanID == nil, let first = beanStore.beans.first {
                    selectedBeanID = first.id
                }
            }
        }
    }

    private func daysSinceRoast(for bean: AppBean) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: bean.roastDate, to: Date()).day ?? 0
    }

    private func saveRecord() {
        guard let bean = selectedBean else {
            alertTitle = "无法保存"
            alertMessage = "请先选择一包豆子。"
            showingAlert = true
            return
        }

        guard isValidInput else {
            alertTitle = "无法保存"
            alertMessage = "请填写有效的正数参数。"
            showingAlert = true
            return
        }

        guard bean.remainingGrams >= dose else {
            alertTitle = "豆子不足"
            alertMessage = "当前剩余 \(bean.remainingGrams, specifier: "%.0f") g，本次需要 \(dose, specifier: "%.0f") g。"
            showingAlert = true
            return
        }

        let record = AppBrewRecord(
            id: UUID(),
            date: Date(),
            dose: dose,
            water: water,
            temperature: temperature,
            duration: duration,
            beanID: bean.id,
            isBest: isBest
        )

        brewStore.add(record)
        beanStore.deductGrams(for: bean.id, grams: dose)

        isBest = false
        alertTitle = "已保存"
        alertMessage = "冲煮记录已保存，并扣减 \(dose, specifier: "%.0f") g 豆子。"
        showingAlert = true
    }
}