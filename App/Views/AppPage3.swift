import SwiftUI
import Foundation

struct AppPage3View: View {
    @EnvironmentObject var store: AppStore
    @State private var goalText: String = ""
    @State private var showClearConfirm: Bool = false
    @State private var showSavedToast: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    AppPage3GoalCard(onSave: "") {
                        saveGoal()
                    }
                } header: {
                    Text("每日目标")
                } footer: {
                    if !isGoalValid {
                        Text("目标需在 500–5000 毫升之间")
                            .foregroundStyle(.red)
                    } else {
                        Text("每天喝够水，身体更轻松")
                    }
                }

                Section {
                    AppPage3InfoCard(store: store)
                } header: {
                    Text("数据概览")
                }

                Section {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("清空所有记录", systemImage: "trash")
                    }
                    .disabled(store.records.isEmpty)
                } header: {
                    Text("数据管理")
                } footer: {
                    Text("清空后所有饮水记录将被删除，无法恢复。")
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("设置")
            .onAppear {
                goalText = "\(store.dailyGoal)"
            }
            .alert("确认清空", isPresented: $showClearConfirm) {
                Button("取消", role: .cancel) { }
                Button("清空", role: .destructive) {
                    clearAll()
                }
            } message: {
                Text("将删除所有饮水记录，且无法恢复。")
            }
            .alert("已保存", isPresented: $showSavedToast) {
                Button("好", role: .cancel) { }
            } message: {
                Text("每日目标已更新")
            }
        }
    }

    private var isGoalValid: Bool {
        guard let value = Int(goalText), (500...5000).contains(value) else {
            return false
        }
        return true
    }

    private func saveGoal() {
        guard let newGoal = Int(goalText), (500...5000).contains(newGoal) else {
            return
        }
        store.dailyGoal = newGoal
        store.save()
        showSavedToast = true
    }

    func clearAll() {
        store.records.removeAll()
        store.save()
    }
}

struct AppPage3GoalCard: View {
    @Binding var goalText: String
    let onSave: () -> Void

    @State private var draftValue: Double = 2000

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("每天目标")
                    .font(.body)
                Spacer()
                TextField("2000", text: $goalText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 96)
                Text("毫升")
                    .foregroundStyle(.secondary)
            }

            Slider(value: $draftValue, in: 500...5000, step: 50) {
                Text("目标")
            } onEditingChanged: { editing in
                if !editing {
                    goalText = "\(Int(draftValue))"
                }
            }

            HStack {
                Text("范围 500–5000 毫升")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("保存") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            if let value = Double(goalText) {
                draftValue = min(max(value, 500), 5000)
            }
        }
        .onChange(of: goalText) { _, newValue in
            if let value = Double(newValue) {
                draftValue = min(max(value, 500), 5000)
            }
        }
    }

    private var isValid: Bool {
        guard let value = Int(goalText), (500...5000).contains(value) else {
            return false
        }
        return true
    }
}

struct AppPage3InfoCard: View {
    @ObservedObject var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("今日饮水", systemImage: "drop.fill")
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(todayTotal) 毫升")
                    .font(.title3.bold())
            }

            HStack {
                Label("今日记录", systemImage: "list.bullet")
                Spacer()
                Text("\(todayCount) 条")
            }

            HStack {
                Label("总记录", systemImage: "archivebox")
                Spacer()
                Text("\(store.records.count) 条")
            }

            HStack {
                Label("每日目标", systemImage: "target")
                Spacer()
                Text("\(store.dailyGoal) 毫升")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var todayRecords: [AppDrinkRecord] {
        store.records.filter { Calendar.current.isDateInToday($0.date) }
    }

    var todayTotal: Int {
        todayRecords.reduce(0) { $0 + $1.amount }
    }

    private var todayCount: Int {
        todayRecords.count
    }
}