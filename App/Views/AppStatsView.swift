import SwiftUI

struct AppStatsView: View {
    private struct StatItem: Identifiable {
        let id = UUID()
        let name: String
        let amount: Double
        let icon: String
        let color: Color
    }

    private let items: [StatItem] = [
        StatItem(name: "餐饮", amount: 1250.80, icon: "fork.knife", color: .orange),
        StatItem(name: "交通", amount: 640.50, icon: "car.fill", color: .blue),
        StatItem(name: "购物", amount: 2330.00, icon: "bag.fill", color: .purple),
        StatItem(name: "居住", amount: 4200.00, icon: "house.fill", color: .green),
        StatItem(name: "娱乐", amount: 880.00, icon: "gamecontroller.fill", color: .pink),
        StatItem(name: "医疗", amount: 350.20, icon: "cross.case.fill", color: .red)
    ]

    private var totalAmount: Double {
        items.reduce(0) { $0 + $1.amount }
    }

    private var averageAmount: Double {
        items.isEmpty ? 0 : totalAmount / Double(items.count)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("本月总支出")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("¥\(totalAmount, specifier: "%.2f")")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)

                        HStack(spacing: 16) {
                            Label {
                                Text("\(items.count) 个分类")
                            } icon: {
                                Image(systemName: "square.grid.2x2")
                            }

                            Label {
                                Text("平均 ¥\(averageAmount, specifier: "%.2f")")
                            } icon: {
                                Image(systemName: "chart.bar.xaxis")
                            }
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section("分类统计") {
                    ForEach(items) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(item.color.gradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.body)
                                Text("¥\(item.amount, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            ProgressView(value: item.amount, total: totalAmount)
                                .frame(width: 80)
                                .tint(item.color)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("统计")
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
    }
}