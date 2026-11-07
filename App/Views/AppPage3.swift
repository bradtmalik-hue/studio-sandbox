import SwiftUI

struct AppPage3View: View {
    @EnvironmentObject var store: AppStore
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage3SummaryCard(store: store)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                Section("默认参与人数") {
                    HStack {
                        Text("默认人数")
                        Spacer()
                        Stepper(value: $store.defaultParticipantCount, in: 1...100) {
                            Text("\(store.defaultParticipantCount) 人")
                                .frame(minWidth: 48, alignment: .trailing)
                        }
                    }
                    Picker("快速选择", selection: $store.defaultParticipantCount) {
                        ForEach([2, 3, 4, 5, 6, 8, 10, 12], id: \.self) { count in
                            Text("\(count) 人").tag(count)
                        }
                    }
                    Button {
                        store.defaultParticipantCount = 4
                        showResetConfirmation = true
                    } label: {
                        Label("恢复默认 4 人", systemImage: "arrow.counterclockwise")
                    }
                }

                Section("说明") {
                    AppPage3InfoRow(icon: "person.2.fill", text: "记账时参与人数会自动填入这里设置的默认值")
                    AppPage3InfoRow(icon: "checkmark.circle.fill", text: "可以在记账页手动修改单笔参与人数")
                    AppPage3InfoRow(icon: "square.and.arrow.down.fill", text: "修改后立即生效，无需额外保存")
                }

                if store.expenses.isEmpty {
                    Section {
                        AppPage3EmptyView()
                    }
                } else {
                    Section("数据概览") {
                        HStack {
                            Text("账单总数")
                            Spacer()
                            Text("\(store.expenses.count) 笔")
                        }
                        HStack {
                            Text("合计金额")
                            Spacer()
                            Text(currencyString(store.totalAmount))
                        }
                        HStack {
                            Text("平均每笔")
                            Spacer()
                            Text(currencyString(store.averagePerExpense))
                        }
                        HStack {
                            Text("最近一笔")
                            Spacer()
                            if let latest = store.expenses.sorted(by: { $0.date > $1.date }).first {
                                Text(latest.title)
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("无")
                            }
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .contentMargins(.bottom, 96, for: .scrollContent)
            .alert("已恢复默认参与人数", isPresented: $showResetConfirmation) {
                Button("好", role: .cancel) { }
            } message: {
                Text("新的账单将默认填入 4 人")
            }
        }
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: NSNumber(value: value)) ?? "¥0.00"
    }
}

struct AppPage3SummaryCard: View {
    let store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("当前设置", systemImage: "gear")
                    .font(.headline)
                Spacer()
            }
            HStack {
                Text("默认参与人数")
                Spacer()
                Text("\(store.defaultParticipantCount) 人")
                    .bold()
            }
            Divider()
            if store.expenses.isEmpty {
                Text("还没有账单，新增时会自动带入此人数")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("已有 \(store.expenses.count) 笔账单，最近使用 \(store.expenses.sorted(by: { $0.date > $1.date }).first?.title ?? "无")")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

struct AppPage3InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}

struct AppPage3EmptyView: View {
    var body: some View {
        ContentUnavailableView {
            Label("暂无账单", systemImage: "tray")
        } description: {
            Text("去「记一笔」添加第一笔聚会花费")
        }
    }
}