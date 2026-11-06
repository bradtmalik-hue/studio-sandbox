import SwiftUI

private struct AppMedicineRow: Identifiable {
    let id = UUID()
    let nameZh: String
    let nameEn: String
    let detailZh: String
    let detailEn: String
    let priceZh: String
    let priceEn: String
}

struct AppMedicineListView: View {
    private let demoMedicines: [AppMedicineRow] = [
        AppMedicineRow(
            nameZh: "阿莫西林胶囊",
            nameEn: "Amoxicillin Capsules",
            detailZh: "0.5g · 每日3次",
            detailEn: "0.5g · 3 times daily",
            priceZh: "¥35.50",
            priceEn: "$35.50"
        ),
        AppMedicineRow(
            nameZh: "布洛芬缓释胶囊",
            nameEn: "Ibuprofen ER Capsules",
            detailZh: "0.3g · 必要时服用",
            detailEn: "0.3g · as needed",
            priceZh: "¥22.00",
            priceEn: "$22.00"
        ),
        AppMedicineRow(
            nameZh: "维生素D滴剂",
            nameEn: "Vitamin D Drops",
            detailZh: "400IU · 每日1次",
            detailEn: "400IU · once daily",
            priceZh: "¥68.00",
            priceEn: "$68.00"
        ),
        AppMedicineRow(
            nameZh: "氯雷他定片",
            nameEn: "Loratadine Tablets",
            detailZh: "10mg · 每晚1次",
            detailEn: "10mg · once nightly",
            priceZh: "¥19.80",
            priceEn: "$19.80"
        ),
        AppMedicineRow(
            nameZh: "蒙脱石散",
            nameEn: "Montmorillonite Powder",
            detailZh: "3g · 每日3次",
            detailEn: "3g · 3 times daily",
            priceZh: "¥15.00",
            priceEn: "$15.00"
        ),
        AppMedicineRow(
            nameZh: "对乙酰氨基酚片",
            nameEn: "Acetaminophen Tablets",
            detailZh: "500mg · 发热时服用",
            detailEn: "500mg · for fever",
            priceZh: "¥12.50",
            priceEn: "$12.50"
        )
    ]

    private var isChinese: Bool {
        Locale.current.language.languageCode?.identifier.hasPrefix("zh") == true
    }

    private var navigationTitle: String {
        isChinese ? "药品清单" : "Medicines"
    }

    var body: some View {
        NavigationStack {
            Group {
                if demoMedicines.isEmpty {
                    emptyView
                } else {
                    list
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(isChinese ? "添加药品" : "Add Medicine")
                }
            }
        }
    }

    private var list: some View {
        List {
            ForEach(demoMedicines) { medicine in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isChinese ? medicine.nameZh : medicine.nameEn)
                            .font(.headline)
                        Text(isChinese ? medicine.detailZh : medicine.detailEn)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(isChinese ? medicine.priceZh : medicine.priceEn)
                        .font(.subheadline)
                        .monospacedDigit()
                }
                .padding(.vertical, 2)
            }
        }
        .contentMargins(.bottom, 96, for: .scrollContent)
    }

    private var emptyView: some View {
        ContentUnavailableView(
            isChinese ? "暂无药品" : "No Medicines",
            systemImage: "pills",
            description: Text(isChinese ? "点击右上角添加第一种药品" : "Tap + to add your first medicine")
        )
    }
}