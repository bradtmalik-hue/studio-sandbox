import SwiftUI

struct AppMedicineListView: View {
    @State private var medicines: [MedicineReminderItem] = MedicineReminderItem.samples

    private var isChinese: Bool {
        Locale.preferredLanguages.first?.hasPrefix("zh") == true
    }

    var body: some View {
        NavigationStack {
            Group {
                if medicines.isEmpty {
                    emptyView
                } else {
                    listContent
                }
            }
            .navigationTitle(isChinese ? "药品" : "Medicines")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addSampleMedicine()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(isChinese ? "添加药品" : "Add Medicine")
                }
            }
        }
    }

    private var listContent: some View {
        List {
            ForEach(medicines) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                    Text(item.dosage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(formattedDate(item.nextDoseDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
            .onDelete(perform: deleteItems)
        }
        .contentMargins(.bottom, 96, for: .scrollContent)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "pills")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(isChinese ? "暂无药品，点击右上角添加" : "No medicines yet. Tap + to add.")
                .font(.headline)
            Text(isChinese ? "记录每个药品的用法和下次服药时间" : "Track dosage and next dose time.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func addSampleMedicine() {
        let newItem: MedicineReminderItem
        if isChinese {
            newItem = MedicineReminderItem(
                name: "阿司匹林",
                dosage: "每日一次，每次一片，饭后服用",
                nextDoseDate: Date().addingTimeInterval(86400)
            )
        } else {
            newItem = MedicineReminderItem(
                name: "Aspirin",
                dosage: "Once daily, one tablet after meals",
                nextDoseDate: Date().addingTimeInterval(86400)
            )
        }
        withAnimation {
            medicines.append(newItem)
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        withAnimation {
            medicines.remove(atOffsets: offsets)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if isChinese {
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "M月d日 HH:mm"
        } else {
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "MMM d, HH:mm"
        }
        return formatter.string(from: date)
    }
}

struct MedicineReminderItem: Identifiable {
    let id = UUID()
    let name: String
    let dosage: String
    let nextDoseDate: Date

    static var samples: [MedicineReminderItem] {
        let isChinese = Locale.preferredLanguages.first?.hasPrefix("zh") == true
        return [
            MedicineReminderItem(
                name: isChinese ? "阿司匹林" : "Aspirin",
                dosage: isChinese ? "每日一次，每次一片，饭后服用" : "Once daily, one tablet after meals",
                nextDoseDate: Date().addingTimeInterval(3600)
            ),
            MedicineReminderItem(
                name: isChinese ? "布洛芬" : "Ibuprofen",
                dosage: isChinese ? "每8小时一次，每次一片" : "Every 8 hours, one tablet",
                nextDoseDate: Date().addingTimeInterval(28800)
            ),
            MedicineReminderItem(
                name: isChinese ? "维生素C" : "Vitamin C",
                dosage: isChinese ? "每日一次，每次一片" : "Once daily, one tablet",
                nextDoseDate: Date().addingTimeInterval(86400)
            ),
            MedicineReminderItem(
                name: isChinese ? "阿莫西林" : "Amoxicillin",
                dosage: isChinese ? "每日三次，每次两片" : "Three times daily, two tablets",
                nextDoseDate: Date().addingTimeInterval(21600)
            ),
            MedicineReminderItem(
                name: isChinese ? "氯雷他定" : "Loratadine",
                dosage: isChinese ? "每日一次，每次一片" : "Once daily, one tablet",
                nextDoseDate: Date().addingTimeInterval(43200)
            ),
            MedicineReminderItem(
                name: isChinese ? "奥美拉唑" : "Omeprazole",
                dosage: isChinese ? "每日一次，每次一粒，早餐前" : "Once daily, one capsule before breakfast",
                nextDoseDate: Date().addingTimeInterval(93600)
            ),
            MedicineReminderItem(
                name: isChinese ? "二甲双胍" : "Metformin",
                dosage: isChinese ? "每日两次，每次一片，随餐" : "Twice daily, one tablet with meals",
                nextDoseDate: Date().addingTimeInterval(61200)
            ),
            MedicineReminderItem(
                name: isChinese ? "蒙脱石散" : "Montmorillonite powder",
                dosage: isChinese ? "每日三次，每次一袋" : "Three times daily, one sachet",
                nextDoseDate: Date().addingTimeInterval(75600)
            )
        ]
    }
}