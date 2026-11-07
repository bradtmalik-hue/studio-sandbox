import SwiftUI
import Combine

struct AppPage4View: View {
    @EnvironmentObject var store: AppStore
    @State private var goalText: String = ""
    @State private var goalAmount: Int = 2000
    @State private var showClearConfirm = false
    @State private var showSavedAlert = false
    @State private var showInvalidAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage4Card {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label("当前每日目标", systemImage: "target")
                                Spacer()
                                Text("\(store.dailyGoalML) 毫升")
                                    .foregroundStyle(.secondary)
                            }

                            HStack {
                                TextField("目标毫升数", text: $goalText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 140)

                                Spacer()

                                Stepper("调整", value: Binding(
                                    get: { goalAmount },
                                    set: { newValue in
                                        goalAmount = newValue
                                        goalText = "\(newValue)"
                                    }
                                ), in: 500...5000, step: 50)
                                .labelsHidden()
                            }

                            HStack {
                                Text("建议范围：500 - 5000 毫升")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }

                            Button {
                                saveGoal()
                            } label: {
                                Text("保存目标")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!isValidGoal)
                        }
                    }
                } header: {
                    Text("喝水目标")
                } footer: {
                    Text("一次喝水按 250 毫升估算，建议每天 2000 毫升左右。")
                }

                Section {
                    AppPage4Card {
                        VStack(alignment: .leading, spacing: 12) {
                            AppPage4Row(icon: "list.bullet.clipboard", title: "记录总数", value: "\(store.records.count) 条")
                            Divider()
                            AppPage4Row(icon: "drop.fill", title: "今日已喝", value: "\(store.todayTotal) 毫升")
                            Divider()
                            if let latest = store.latestRecordDate {
                                AppPage4Row(icon: "clock", title: "最近记录", value: Self.chineseDateTime(latest))
                            } else {
                                AppPage4Row(icon: "clock", title: "最近记录", value: "暂无")
                            }
                        }
                    }

                    if store.records.isEmpty {
                        AppPage4EmptyStateView()
                    } else {
                        Button(role: .destructive) {
                            showClearConfirm = true
                        } label: {
                            Label("清空所有记录", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                } header: {
                    Text("数据管理")
                } footer: {
                    Text("清空后所有喝水记录将从本机移除，且无法恢复。")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("设置")
            .onAppear {
                goalAmount = store.dailyGoalML
                goalText = "\(store.dailyGoalML)"
            }
            .alert("确定清空所有喝水记录吗？", isPresented: $showClearConfirm) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) {
                    clearAll()
                }
            } message: {
                Text("将删除 \(store.records.count) 条记录，此操作不可撤销。")
            }
            .alert("已保存", isPresented: $showSavedAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text("每日目标已更新为 \(store.dailyGoalML) 毫升。")
            }
            .alert("目标无效", isPresented: $showInvalidAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text("请输入 500 到 5000 之间的整数。")
            }
        }
    }

    private var isValidGoal: Bool {
        guard let value = Int(goalText), value >= 500, value <= 5000 else {
            return false
        }
        return true
    }

    private func saveGoal() {
        guard let value = Int(goalText), value >= 500, value <= 5000 else {
            showInvalidAlert = true
            return
        }
        store.dailyGoalML = value
        store.save()
        goalAmount = value
        showSavedAlert = true
    }

    private func clearAll() {
        store.records.removeAll()
        store.save()
    }

    private static func chineseDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

struct AppPage4Row: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

struct AppPage4Card<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct AppPage4EmptyStateView: View {
    var body: some View {
        ContentUnavailableView(
            "暂无喝水记录",
            systemImage: "drop",
            description: Text("开始记录第一次喝水吧")
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}