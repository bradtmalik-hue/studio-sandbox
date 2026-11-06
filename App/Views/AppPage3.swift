import SwiftUI
import Foundation

private let AppPage3DateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "yyyy年M月d日"
    return formatter
}()

struct AppPage3View: View {
    @EnvironmentObject var store: AppMedicineStore

    var body: some View {
        NavigationStack {
            Group {
                if store.expiringSoon.isEmpty {
                    AppPage3Empty()
                } else {
                    List {
                        ForEach(store.expiringSoon) { medicine in
                            AppPage3Card(medicine: medicine)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("临期提醒")
        }
    }
}

private struct AppPage3Card: View {
    let medicine: AppMedicine

    var body: some View {
        AppPage3Row(medicine: medicine)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
            .overlay(alignment: .topTrailing) {
                AppPage3DaysBadge(expiryDate: medicine.expiryDate)
                    .padding(12)
            }
    }
}

private struct AppPage3Row: View {
    let medicine: AppMedicine

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(medicine.name)
                .font(.headline)

            HStack(spacing: 12) {
                Label(medicine.location, systemImage: "location")
                Label("\(medicine.quantity) 盒", systemImage: "shippingbox")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text("有效期至 \(AppPage3DateFormatter.string(from: medicine.expiryDate))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 76)
    }
}

private struct AppPage3DaysBadge: View {
    let expiryDate: Date

    private var daysRemaining: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let expiry = Calendar.current.startOfDay(for: expiryDate)
        return Calendar.current.dateComponents([.day], from: today, to: expiry).day ?? 0
    }

    private var badgeText: String {
        if daysRemaining < 0 {
            return "已过期 \(abs(daysRemaining)) 天"
        } else if daysRemaining == 0 {
            return "今天到期"
        } else {
            return "\(daysRemaining) 天后到期"
        }
    }

    private var badgeColor: Color {
        if daysRemaining < 0 {
            return .red
        } else {
            return .orange
        }
    }

    var body: some View {
        Text(badgeText)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(badgeColor))
    }
}

private struct AppPage3Empty: View {
    var body: some View {
        ContentUnavailableView {
            Label("暂无临期药品", systemImage: "checkmark.circle")
        } description: {
            Text("30天内到期的药品会出现在这里，快去检查药箱吧。")
        }
    }
}