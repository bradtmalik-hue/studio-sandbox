import SwiftUI
import Combine

struct AppPage3View: View {
    @EnvironmentObject var store: AppDataStore
    @State private var goalText: String = ""
    @State private var activeAlert: AppPage3Alert?
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage3GoalCard(goalText: $goalText, onSave: saveGoal)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } header: {
                    Text("每日目标")
                } footer: {
                    Text("建议每天饮水 1500–2500 毫升。")
                }

                Section {
                    AppPage3SummaryCard(
                        recordCount: store.records.count,
                        totalML: store.records.reduce(0) { $0 + $1.amountML },
                        dailyGoalML: store.dailyGoalML
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } header: {
                    Text("当前数据")
                }

                Section {
                    Button(role: .destructive) {
                        activeAlert = .clearConfirm
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("清空所有记录")
                        }
                    }
                } header: {
                    Text("数据管理")
                } footer: {
                    Text("清空后历史页将没有记录。")
                }
            }
            .navigationTitle("设置")
            .onAppear {
                goalText = "\(store.dailyGoalML)"
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .clearConfirm:
                    return Alert(
                        title: Text("清空所有记录？"),
                        message: Text("此操作不可撤销。"),
                        primaryButton: .destructive(Text("清空")) {
                            clearRecords()
                        },
                        secondaryButton: .cancel(Text("取消"))
                    )
                case .goalSaved:
                    return Alert(
                        title: Text("目标已保存"),
                        message: Text("新的每日目标已生效。"),
                        dismissButton: .default(Text("好"))
                    )
                case .goalError:
                    return Alert(
                        title: Text("无法保存"),
                        message: Text(errorMessage),
                        dismissButton: .default(Text("好"))
                    )
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }

    private func saveGoal() {
        guard let value = Int(goalText), value >= 500, value <= 10000 else {
            errorMessage = "请输入 500–10000 之间的整数。"
            activeAlert = .goalError
            return
        }
        store.dailyGoalML = value
        store.save()
        activeAlert = .goalSaved
    }

    func clearRecords() {
        store.records.removeAll()
        store.save()
    }
}

private enum AppPage3Alert: String, Identifiable {
    case clearConfirm
    case goalSaved
    case goalError

    var id: String { rawValue }
}

struct AppPage3GoalCard: View {
    @Binding var goalText: String
    let onSave: () -> Void

    private var isGoalValid: Bool {
        guard let value = Int(goalText), value >= 500, value <= 10000 else {
            return false
        }
        return true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("目标毫升数", systemImage: "target")
                Spacer()
            }

            TextField("例如 2000", text: $goalText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("常用 1500") {
                    goalText = "1500"
                }
                Spacer()
                Button("常用 2000") {
                    goalText = "2000"
                }
                Spacer()
                Button("保存目标") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isGoalValid)
            }
        }
        .padding(.vertical, 12)
    }
}

struct AppPage3SummaryCard: View {
    let recordCount: Int
    let totalML: Int
    let dailyGoalML: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if recordCount == 0 {
                AppPage3EmptyState()
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("记录条数")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(recordCount)")
                            .font(.title2.bold())
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("总饮水量")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(totalML) 毫升")
                            .font(.title2.bold())
                    }
                }

                HStack {
                    Text("每日目标")
                    Spacer()
                    Text("\(dailyGoalML) 毫升")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 12)
    }
}

struct AppPage3EmptyState: View {
    var body: some View {
        ContentUnavailableView(
            "暂无记录",
            systemImage: "drop",
            description: Text("去「今天」页添加第一笔喝水记录。")
        )
        .frame(maxWidth: .infinity)
    }
}