import SwiftUI

struct AppPage3View: View {
    @EnvironmentObject var store: AppStore
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    AppPage3GoalEditor(dailyGoal: $store.dailyGoal)
                    Stepper("调整目标", value: $store.dailyGoal, in: 500...5000, step: 50)
                    Text("建议每日饮水 1500–2500 毫升")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("保存目标") {
                        store.save()
                    }
                    .disabled(store.dailyGoal < 500 || store.dailyGoal > 5000)
                } header: {
                    Text("每日目标")
                } footer: {
                    Text("修改后请点击保存，目标会用于今日进度计算。")
                }

                Section {
                    LabeledContent("记录总数", value: "\(store.records.count) 条")
                    LabeledContent("今日已饮", value: "\(Int(store.totalToday)) 毫升")
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("清空所有记录", systemImage: "trash")
                    }
                    .disabled(store.records.isEmpty)
                } header: {
                    Text("数据管理")
                }

                Section {
                    LabeledContent("存储位置", value: "本机")
                    LabeledContent("数据同步", value: "无")
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
            .alert("确认清空所有记录？", isPresented: $showClearConfirm) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) {
                    store.records.removeAll()
                    store.save()
                }
            } message: {
                Text("此操作不可撤销，所有饮水记录都会被删除。")
            }
        }
    }
}

struct AppPage3GoalEditor: View {
    @Binding var dailyGoal: Double

    var body: some View {
        HStack {
            Label("每日目标", systemImage: "target")
            Spacer()
            TextField("2000", value: $dailyGoal, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
            Text("毫升")
                .foregroundStyle(.secondary)
        }
    }
}