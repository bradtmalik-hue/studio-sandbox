import SwiftUI
import Foundation

struct AppPage3View: View {
    @EnvironmentObject var store: AppStore
    @State private var goalInput: String = ""
    @State private var showSavedAlert = false
    @State private var showInvalidAlert = false

    private var currentGoalMl: Double {
        store.dailyGoalMl
    }

    private var parsedGoal: Double? {
        Double(goalInput.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var isGoalValid: Bool {
        guard let goal = parsedGoal else { return false }
        return goal >= 500 && goal <= 5000
    }

    var recordCount: Int {
        store.records.count
    }

    private var averagePerRecordMl: Double {
        guard !store.records.isEmpty else { return 0 }
        let total = store.records.reduce(0) { $0 + $1.amountMl }
        return total / Double(store.records.count)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage3GoalCard(
                        goalMl: currentGoalMl,
                        recordCount: recordCount,
                        averagePerRecordMl: averagePerRecordMl
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                Section("每日喝水目标") {
                    HStack {
                        Text("毫升")
                        Spacer()
                        TextField("2000", text: $goalInput)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 140)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("快捷设置")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach([1200, 1500, 2000, 2500, 3000], id: \.self) { value in
                                    AppPage3PresetButton(
                                        amount: value,
                                        isSelected: Int(currentGoalMl) == value
                                    ) {
                                        goalInput = "\(value)"
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                Section {
                    Button(action: saveGoal) {
                        HStack {
                            Spacer()
                            Label("保存目标", systemImage: "checkmark.circle.fill")
                                .font(.body.weight(.semibold))
                            Spacer()
                        }
                    }
                    .disabled(!isGoalValid)
                    .foregroundStyle(isGoalValid ? Color.accentColor : Color.gray)
                    .listRowBackground(
                        isGoalValid ? Color.accentColor.opacity(0.10) : Color.gray.opacity(0.08)
                    )

                    Button {
                        goalInput = "2000"
                    } label: {
                        HStack {
                            Spacer()
                            Label("恢复默认 2000 毫升", systemImage: "arrow.counterclockwise")
                            Spacer()
                        }
                    }
                }

                if !goalInput.isEmpty && !isGoalValid {
                    Section {
                        Label("目标需在 500 到 5000 毫升之间", systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .contentMargins(.bottom, 96, for: .scrollContent)
            .onAppear {
                goalInput = String(Int(store.dailyGoalMl))
            }
            .alert("目标已保存", isPresented: $showSavedAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text("每日喝水目标已更新为 \(Int(store.dailyGoalMl)) 毫升。")
            }
            .alert("目标无效", isPresented: $showInvalidAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text("请输入 500 到 5000 之间的毫升数。")
            }
        }
    }

    private func saveGoal() {
        guard isGoalValid, let goal = parsedGoal else {
            showInvalidAlert = true
            return
        }

        store.dailyGoalMl = goal
        store.save()
        showSavedAlert = true
    }
}

private struct AppPage3GoalCard: View {
    let goalMl: Double
    let recordCount: Int
    let averagePerRecordMl: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("当前目标", systemImage: "drop.circle.fill")
                    .font(.headline)
                Spacer()
                Text("\(Int(goalMl)) 毫升")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)
            }

            Divider()

            HStack {
                Label("历史记录", systemImage: "tray.full.fill")
                Spacer()
                Text("\(recordCount) 条")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("平均每次", systemImage: "chart.bar.fill")
                Spacer()
                Text("\(Int(averagePerRecordMl)) 毫升")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.gray.opacity(0.08))
        )
    }
}

private struct AppPage3PresetButton: View {
    let amount: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(amount)")
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.12))
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

private struct AppPage3EmptyView: View {
    var body: some View {
        ContentUnavailableView(
            "暂无记录",
            systemImage: "drop.triangle",
            description: Text("开始记录喝水后，这里会显示统计数据。")
        )
    }
}