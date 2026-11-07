import SwiftUI

struct AppPage2SummaryCard: View {
    let totalAmount: Double
    let count: Int
    let latestDate: Date?
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("总支出")
                .font(.headline)
            Text(totalAmount, format: .currency(code: currencyCode))
                .font(.title2)
            Text("共 \(count) 笔")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let latestDate {
                Text("最近一笔：\(latestDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct AppPage2BalanceRow: View {
    let balance: AppBalance
    let currencyCode: String

    var body: some View {
        HStack {
            Text(balance.name)
            Spacer()
            Text(balance.amount, format: .currency(code: currencyCode))
                .foregroundStyle(balance.amount >= 0 ? .primary : .red)
        }
    }
}

struct AppPage2TransferRow: View {
    let transfer: AppTransfer
    let currencyCode: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(transfer.from)
                    .font(.subheadline)
                Text("转给")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(transfer.to)
                    .font(.subheadline)
            }
            Spacer()
            Text(transfer.amount, format: .currency(code: currencyCode))
                .font(.headline)
        }
    }
}

struct AppPage2ExpenseRow: View {
    let expense: AppExpense
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(expense.title)
                .font(.headline)
            Text("\(expense.paidBy) · \(expense.date.formatted(date: .numeric, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(expense.amount, format: .currency(code: currencyCode))
                .font(.subheadline)
        }
    }
}

struct AppPage2View: View {
    let balances: [AppBalance]
    let dict: [String: Double]
    let transfers: [AppTransfer]
    let creditors: [(name: String, amount: Double)]
    let debtors: [(name: String, amount: Double)]
    let result: [AppTransfer]
    let filtered: [AppExpense]

    var body: some View {
        List {
            Section {
                AppPage2SummaryCard(
                    totalAmount: filtered.reduce(0) { $0 + $1.amount },
                    count: filtered.count,
                    latestDate: filtered.map(\.date).max(),
                    currencyCode: "CNY"
                )
            }

            if !balances.isEmpty {
                Section("余额") {
                    ForEach(balances, id: \.name) { balance in
                        AppPage2BalanceRow(balance: balance, currencyCode: "CNY")
                    }
                }
            }

            if !transfers.isEmpty {
                Section("建议转账") {
                    ForEach(transfers, id: \.self) { transfer in
                        AppPage2TransferRow(transfer: transfer, currencyCode: "CNY")
                    }
                }
            }

            if !creditors.isEmpty {
                Section("应收") {
                    ForEach(creditors, id: \.name) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text(item.amount, format: .currency(code: "CNY"))
                        }
                    }
                }
            }

            if !debtors.isEmpty {
                Section("应付") {
                    ForEach(debtors, id: \.name) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text(item.amount, format: .currency(code: "CNY"))
                        }
                    }
                }
            }

            Section("明细") {
                ForEach(filtered, id: \.id) { expense in
                    AppPage2ExpenseRow(expense: expense, currencyCode: "CNY")
                }
            }
        }
        .navigationTitle("结算")
    }
}

#Preview {
    NavigationStack {
        AppPage2View(
            balances: [
                AppBalance(id: UUID(), name: "张三", amount: 120),
                AppBalance(id: UUID(), name: "李四", amount: -80)
            ],
            dict: ["张三": 120, "李四": 40],
            transfers: [
                AppTransfer(id: UUID(), from: "李四", to: "张三", amount: 40)
            ],
            creditors: [("张三", 80)],
            debtors: [("李四", 80)],
            result: [
                AppTransfer(id: UUID(), from: "李四", to: "张三", amount: 40)
            ],
            filtered: []
        )
    }
}
