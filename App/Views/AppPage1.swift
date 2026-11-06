import SwiftUI
import Foundation

struct AppPage1View: View {
    @EnvironmentObject private var store: AppMedicineStore

    var body: some View {
        NavigationStack {
            Group {
                if store.sortedByExpiry.isEmpty {
                    AppPage1Empty()
                } else {
                    List {
                        ForEach(store.sortedByExpiry) { medicine in
                            AppPage1Row(medicine: medicine)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("药品列表")
        }
    }
}

struct AppPage1Row: View {
    let medicine: AppMedicine

    private var isExpiringSoon: Bool {
        let now = Date()
        let threshold = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now
        return medicine.expiryDate < threshold && medicine.expiryDate >= now
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(medicine.name)
                    .font(.headline)
                Text("位置：\(medicine.location)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("数量：\(medicine.quantity)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(Self.dateFormatter.string(from: medicine.expiryDate))
                    .font(.subheadline)
                    .foregroundStyle(isExpiringSoon ? Color.orange : .secondary)
                if isExpiringSoon {
                    Text("临期")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange, in: Capsule())
                }
            }
        }
        .padding(.vertical, 6)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()
}

struct AppPage1Empty: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pills")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("还没有登记药品")
                .font(.headline)
            Text("去「添加一盒药」页签登记新药，\n过期前这里会提醒你。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}