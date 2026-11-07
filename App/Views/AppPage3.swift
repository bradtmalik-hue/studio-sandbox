import SwiftUI
import Combine

struct AppPage3View: View {
    @EnvironmentObject var store: AppStore
    @State private var budgetText: String = ""
    @State private var showingSavedAlert = false
    @State private var showingResetAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage3BudgetCard(
                        monthlyBudget: store.monthlyBudget,
                        todayTotal: store.todayTotal
                    )
                } header: {
                    Text("当前预算")
                }

                Section {
                    HStack {
                        Text("每月预算")
                        Spacer()
                        TextField("3000", text: $budgetText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                        Text("元")
                    }

                    Stepper(
                        value: Binding(
                            get: { Double(budgetText) ?? 3000 },
                            set: { budgetText = String(format: "%.0f", $0) }
                        ),
                        in: 100.0...100000.0,
                        step: 100.0
                    ) {
                        Text("调整金额")
                    }

                    Button {
                        saveBudget()
                    } label: {
                        Text("保存预算")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(parsedBudget == nil || (parsedBudget ?? 0) <= 0)
                } header: {
                    Text("修改预算")
                } footer: {
                    Text("默认预算是 3000 元。超过后首页合计会显示为红色。")
                }

                Section {
                    AppPage3InfoRow(
                        icon: "info.circle",
                        text: "预算金额只影响首页合计的颜色提醒，不会阻止记录支出。"
                    )
                    AppPage3InfoRow(
                        icon: "exclamationmark.triangle.fill",
                        text: "当今日合计超过每月预算时，首页金额会变为红色。"
                    )
                }

                Section {
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Text("恢复默认预算")
                    }
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("设置")
            .onAppear {
                if budgetText.isEmpty {
                    budgetText = String(format: "%.0f", store.monthlyBudget)
                }
            }
            .alert("预算已保存", isPresented: $showingSavedAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text("新的每月预算已生效。")
            }
            .alert("恢复默认预算？", isPresented: $showingResetAlert) {
                Button("取消", role: .cancel) {}
                Button("恢复", role: .destructive) {
                    budgetText = "3000"
                    saveBudget()
                }
            } message: {
                Text("预算将恢复为 3000 元。")
            }
        }
    }

    private var parsedBudget: Double? {
        Double(budgetText.replacingOccurrences(of: ",", with: ""))
    }

    private func saveBudget() {
        guard let value = parsedBudget, value > 0 else { return }
        store.monthlyBudget = value
        store.save()
        showingSavedAlert = true
    }
}

struct AppPage3BudgetCard: View {
    let monthlyBudget: Double
    let todayTotal: Double

    private var overAmount: Double {
        max(0, todayTotal - monthlyBudget)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("每月预算", systemImage: "creditcard")
                Spacer()
                Text(String(format: "¥%.2f", monthlyBudget))
                    .font(.title2.bold())
            }

            HStack {
                Label("今日已花", systemImage: "yensign.circle")
                Spacer()
                Text(String(format: "¥%.2f", todayTotal))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(todayTotal > monthlyBudget ? Color.red : Color.primary)
            }

            if todayTotal > monthlyBudget {
                Label(
                    String(format: "已超过预算 ¥%.2f", overAmount),
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.footnote)
                .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AppPage3InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AppPage3EmptyState: View {
    var body: some View {
        ContentUnavailableView(
            "还没有设置",
            systemImage: "gearshape",
            description: Text("每月预算会显示在这里。")
        )
    }
}