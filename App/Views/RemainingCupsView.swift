import SwiftUI
import Foundation

struct AppRemainingCupsView: View {
    @Binding var beans: [AppCoffeeBean]

    private var totalRemainingCups: Int {
        beans.reduce(0) { partial, bean in
            partial + (bean.defaultCupGrams > 0 ? Int(bean.remainingGrams / bean.defaultCupGrams) : 0)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if beans.isEmpty {
                emptyState
            } else {
                summaryBar

                List {
                    ForEach($beans) { $bean in
                        AppBeanRemainingRow(bean: $bean)
                    }
                    .listRowBackground(Color(.secondarySystemGroupedBackground))
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("剩余杯数")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Text("调节每杯克数，点按按钮模拟消耗一杯。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    private var summaryBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "cup.and.saucer.fill")
                .foregroundStyle(.brown)

            Text("当前库存可冲煮")
                .foregroundStyle(.secondary)

            Text("\(totalRemainingCups)")
                .font(.headline)
                .foregroundStyle(.brown)

            Text("杯")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cup.and.saucer")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.tertiary)

            Text("还没有豆子")
                .font(.title3.bold())

            Text("先去库存添加一支豆子，这里会显示可冲煮的剩余杯数。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct AppBeanRemainingRow: View {
    @Binding var bean: AppCoffeeBean

    private var remainingCups: Int {
        bean.defaultCupGrams > 0 ? Int(bean.remainingGrams / bean.defaultCupGrams) : 0
    }

    private var restDays: Int {
        Calendar.current.dateComponents([.day], from: bean.roastDate, to: Date()).day ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(bean.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(remainingCups) 杯")
                    .font(.title3.bold())
                    .foregroundStyle(.brown)
            }

            HStack(spacing: 12) {
                Text(bean.roastDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("·")
                    .foregroundStyle(.secondary)

                Text("已养豆 \(restDays) 天")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Stepper(value: $bean.defaultCupGrams, in: 5...30, step: 1) {
                Text("每杯 \(Int(bean.defaultCupGrams)) 克")
                    .font(.subheadline)
            }

            Divider()

            Button {
                bean.remainingGrams = max(0, bean.remainingGrams - bean.defaultCupGrams)
            } label: {
                Label("模拟消耗一杯", systemImage: "minus.circle.fill")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.brown)
            .disabled(bean.remainingGrams <= 0)
        }
        .padding(.vertical, 4)
    }
}