import SwiftUI

private enum AppPage3Format {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()
}

struct AppPage3View: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var onlyReminderEnabled = false
    @State private var daysFilter = 30

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppPage3FilterBar(searchText: $searchText,
                                  onlyReminderEnabled: $onlyReminderEnabled,
                                  daysFilter: $daysFilter)
                AppPage3SummaryCard(total: filteredMedicines.count,
                                    soonest: filteredMedicines.first?.expiryDate,
                                    enabledCount: filteredMedicines.filter(\.reminderEnabled).count)
                List {
                    ForEach(filteredMedicines) { medicine in
                        AppPage3Row(medicine: medicine)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(medicine)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.insetGrouped)
                .contentMargins(.bottom, 96, for: .scrollContent)
                .overlay {
                    if filteredMedicines.isEmpty {
                        emptyState
                    }
                }
            }
            .navigationTitle("临期提醒")
        }
    }

    var filteredMedicines: [AppMedicineBox] {
        let now = Date()
        let calendar = Calendar.current
        return store.medicines
            .filter { medicine in
                let days = calendar.dateComponents([.day], from: now, to: medicine.expiryDate).day ?? 0
                return days >= 0 && days <= 30
            }
            .filter { medicine in
                !onlyReminderEnabled || medicine.reminderEnabled
            }
            .filter { medicine in
                let days = calendar.dateComponents([.day], from: now, to: medicine.expiryDate).day ?? 0
                return days <= daysFilter
            }
            .filter { medicine in
                if searchText.isEmpty { return true }
                return medicine.name.localizedCaseInsensitiveContains(searchText) ||
                       medicine.category.localizedCaseInsensitiveContains(searchText) ||
                       medicine.storageLocation.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.expiryDate < $1.expiryDate }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("暂无临期药品", systemImage: "calendar.badge.checkmark")
        } description: {
            Text("未来30天内没有到期的药。")
        } actions: {
            Button("去添加药品") { }
        }
    }

    func delete(_ medicine: AppMedicineBox) {
        withAnimation {
            store.medicines.removeAll { $0.id == medicine.id }
            saveMedicines()
        }
    }

    private func saveMedicines() {
        do {
            let data = try JSONEncoder().encode(store.medicines)
            try data.write(to: store.fileURL)
        } catch {
            // 忽略写入失败，界面数据仍然更新
        }
    }
}

struct AppPage3FilterBar: View {
    @Binding var searchText: String
    @Binding var onlyReminderEnabled: Bool
    @Binding var daysFilter: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索药名、位置或分类", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            HStack {
                Toggle(isOn: $onlyReminderEnabled) {
                    Text("只看已开启提醒")
                        .font(.subheadline)
                }
                .toggleStyle(.switch)
                Spacer()
            }
            .padding(.horizontal)

            Picker("提醒窗口", selection: $daysFilter) {
                Text("7天内").tag(7)
                Text("14天内").tag(14)
                Text("30天内").tag(30)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

struct AppPage3SummaryCard: View {
    let total: Int
    let soonest: Date?
    let enabledCount: Int

    var body: some View {
        HStack(spacing: 16) {
            AppPage3Metric(title: "临期总数",
                           value: "\(total)",
                           unit: "盒",
                           icon: "pills.fill",
                           color: .orange)
            AppPage3Metric(title: "最近到期",
                           value: soonest.map { AppPage3Format.dateFormatter.string(from: $0) } ?? "--",
                           unit: "",
                           icon: "calendar.badge.clock",
                           color: .red)
            AppPage3Metric(title: "已开启提醒",
                           value: "\(enabledCount)",
                           unit: "盒",
                           icon: "bell.badge.fill",
                           color: .blue)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct AppPage3Metric: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundColor(color)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AppPage3Row: View {
    let medicine: AppMedicineBox

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(medicine.name)
                    .font(.headline)
                HStack(spacing: 8) {
                    Label(medicine.category, systemImage: "tag")
                    Label(medicine.storageLocation, systemImage: "location")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(expiryText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(expiryColor)
                Text("\(medicine.quantity) \(medicine.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Image(systemName: medicine.reminderEnabled ? "bell.fill" : "bell.slash")
                    .font(.caption)
                    .foregroundColor(medicine.reminderEnabled ? .blue : .secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var expiryText: String {
        AppPage3Format.dateFormatter.string(from: medicine.expiryDate)
    }

    var expiryColor: Color {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: medicine.expiryDate).day ?? 0
        if days <= 7 { return .red }
        if days <= 14 { return .orange }
        return .yellow
    }
}