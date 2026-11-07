import SwiftUI
import Foundation

struct AppPage2View: View {
    @EnvironmentObject var store: AppStore

    private var balances: [String: Double] {
        computeBalances(store.expenses)
    }

    private var personBalances: [AppPage2PersonBalance] {
        balances.map { AppPage2PersonBalance(name: $0.key, netAmount: $0.value) }
            .sorted { abs($0.netAmount) > abs($1.netAmount) }
    }

    private var transfers: [AppPage2Transfer] {
        var creditors = personBalances.filter { $0.netAmount > 0.001 }
        var debtors = personBalances.filter { $0.netAmount < -0.001 }
        var result: [AppPage2Transfer] = []
        while !creditors.isEmpty && !debtors.isEmpty {
            creditors.sort { $0.netAmount > $1.netAmount }
            debtors.sort { $0.netAmount < $1.netAmount }
            let creditor = creditors[0]
            let debtor = debtors[0]
            let amount = min(creditor.netAmount, -debtor.netAmount)
            result.append(AppPage2Transfer(from: debtor.name, to: creditor.name, amount: amount))
            var updatedCreditor = creditor
            var updatedDebtor = debtor
            updatedCreditor.netAmount -= amount
            updatedDebtor.netAmount += amount
            creditors[0] = updatedCreditor
            debtors[0] = updatedDebtor
            if abs(creditors[0].netAmount) < 0.001 {
                creditors.removeFirst()
            }
            if abs(debtors[0].netAmount) < 0.001 {
                debtors.removeFirst()
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            if store.expenses.isEmpty {
                ContentUnavailableView {
                    Label("还没有聚会账目", systemImage: "person.2.slash")
                } description: {
                    Text("记一笔聚会花费后，这里会显示每人应付多少和谁该转给谁。")
                }
            } else {
                List {
                    AppPage2SummaryCard(
                        totalAmount: store.totalAmount,
                        averagePerExpense: store.averagePerExpense,
                        expenseCount: store.expenses.count
                    )
                    Section("每人应收/应付") {
                        ForEach(personBalances) { person in
                            AppPage2PersonRow(person: person)
                        }
                    }
                    Section("转账建议") {
                        ForEach(transfers) { transfer in
                            AppPage2TransferRow(transfer: transfer)
                        }
                    }
                    Section("开销明细") {
                        ForEach(store.sortedExpenses) { expense in
                            AppPage2ExpenseRow(expense: expense)
                        }
                    }
                }
                .contentMargins(.bottom, 96, for: .scrollContent)
            }
        }
        .navigationTitle("结果")
    }

    private func computeBalances(_ expenses: [AppExpense]) -> [String: Double] {
        var balances: [String: Double] = [:]
        for expense in expenses {
            let share = expense.amount / Double(max(expense.participantCount, 1))
            for participant in expense.participants {
                if participant == expense.payer {
                    balances[participant, default: 0] += share * Double(max(expense.participantCount - 1, 0))
                } else {
                    balances[participant, default: 0] -= share
                }
            }
        }
        return balances
    }
}

struct AppPage2SummaryCard: View {
    let totalAmount: Double
    let averagePerExpense: Double
    let expenseCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("总览")
                .font(.headline)
                .foregroundColor(.secondary)
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("总花费")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(totalAmount))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    Text("平均每笔")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(averagePerExpense))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Text("共 \(expenseCount) 笔聚会花费")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .padding(.vertical, 4)
    }

    private func formatCurrency(_ value: Double) -> String {
        String(format: "¥%.2f", value)
    }
}

struct AppPage2PersonRow: View {
    let person: AppPage2PersonBalance

    var body: some View {
        HStack {
            Image(systemName: person.netAmount >= 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundColor(person.netAmount >= 0 ? .green : .red)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(.body)
                Text(person.netAmount >= 0 ? "应收" : "应付")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(formatCurrency(person.netAmount))
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(person.netAmount >= 0 ? .green : .red)
        }
        .padding(.vertical, 4)
    }

    private func formatCurrency(_ value: Double) -> String {
        let absValue = abs(value)
        let sign = value >= 0 ? "" : "-"
        return sign + String(format: "¥%.2f", absValue)
    }
}

struct AppPage2TransferRow: View {
    let transfer: AppPage2Transfer

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(transfer.from)
                    .font(.body)
                Text("转给")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(transfer.to)
                    .font(.body)
                Text(formatCurrency(transfer.amount))
                    .font(.callout)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatCurrency(_ value: Double) -> String {
        String(format: "¥%.2f", value)
    }
}

struct AppPage2ExpenseRow: View {
    let expense: AppExpense

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(expense.title)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                Text(formatCurrency(expense.amount))
                    .font(.body)
                    .fontWeight(.semibold)
            }
            HStack {
                Label(expense.payer, systemImage: "person.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatDate(expense.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack {
                Text("每人 \(formatCurrency(expense.perPersonAmount))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(expense.participantCount)人参与")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatCurrency(_ value: Double) -> String {
        String(format: "¥%.2f", value)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

struct AppPage2PersonBalance: Identifiable {
    let name: String
    var netAmount: Double
    var id: String { name }
}

struct AppPage2Transfer: Identifiable {
    let from: String
    let to: String
    let amount: Double
    var id: String { "\(from)-\(to)-\(amount)" }
}