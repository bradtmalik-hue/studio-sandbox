import SwiftUI

struct AppPage3View: View {
    @EnvironmentObject private var store: AppStore
    @State private var goalText: String = ""
    @State private var sliderValue: Double = 2000
    @State private var showClearAlert = false
    @State private var showGoalSavedAlert = false
    @State private var showClearDoneAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage3GoalCard(
                        goalText: $goalText,
                        sliderValue: $sliderValue,
                        onSave: saveGoal
                    )
                } header: {
                    Text("每日目标")
                } footer: {
                    Text("建议在 500–5000 ml 之间设置。")
                }

                Section {
                    AppPage3Row(
                        icon: "drop.fill",
                        title: "今日已喝",
                        detail: "\(store.totalToday) ml"
                    )
                    AppPage3Row(
                        icon: "target",
                        title: "当前目标",
                        detail: "\(store.dailyGoalML) ml"
                    )
                    AppPage3Row(
                        icon: "list.bullet.rectangle",
                        title: "历史记录总数",
                        detail: "\(store.entries.count) 条"
                    )
                } header: {
                    Text("当前数据")
                }

                if store.entries.isEmpty {
                    Section {
                        AppPage3Empty()
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("清空所有记录")
                        }
                    }
                } header: {
                    Text("数据维护")
                } footer: {
                    Text("清空后将无法恢复，请确认后再操作。")
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("设置")
            .onAppear {
                goalText = "\(store.dailyGoalML)"
                sliderValue = Double(store.dailyGoalML)
            }
            .alert("确认清空所有记录？", isPresented: $showClearAlert) {
                Button("取消", role: .cancel) { }
                Button("清空", role: .destructive) {
                    clearAllRecords()
                }
            } message: {
                Text("将删除 \(store.entries.count) 条喝水记录，此操作无法恢复。")
            }
            .alert("已保存", isPresented: $showGoalSavedAlert) {
                Button("好", role: .cancel) { }
            } message: {
                Text("每日目标已更新。")
            }
            .alert("已清空", isPresented: $showClearDoneAlert) {
                Button("好", role: .cancel) { }
            } message: {
                Text("所有喝水记录均已删除。")
            }
        }
    }

    private func saveGoal() {
        guard let value = Int(goalText), value >= 500, value <= 5000 else { return }
        store.dailyGoalML = value
        sliderValue = Double(value)
        store.save()
        showGoalSavedAlert = true
    }

    private func clearAllRecords() {
        store.entries.removeAll()
        store.save()
        showClearDoneAlert = true
    }
}

private struct AppPage3GoalCard: View {
    @Binding var goalText: String
    @Binding var sliderValue: Double
    let onSave: () -> Void

    private var isValidGoal: Bool {
        guard let value = Int(goalText), value >= 500, value <= 5000 else { return false }
        return true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "drop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("每天喝够水")
                    .font(.headline)
            }

            TextField("目标毫升数", text: $goalText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)

            Slider(value: $sliderValue, in: 500...5000, step: 50) { editing in
                if !editing {
                    goalText = "\(Int(sliderValue))"
                }
            }

            HStack {
                Text("500 ml")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(sliderValue)) ml")
                    .font(.headline)
                    .foregroundStyle(.blue)
                Spacer()
                Text("5000 ml")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                onSave()
            } label: {
                Text("保存目标")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValidGoal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

private struct AppPage3Row: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 28, height: 28)
                .foregroundStyle(.blue)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )

            Text(title)
                .font(.body)

            Spacer()

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct AppPage3Empty: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.triangle")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("还没有喝水记录")
                    .font(.headline)
                Text("去「今天」页添加第一条记录吧。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
    }
}