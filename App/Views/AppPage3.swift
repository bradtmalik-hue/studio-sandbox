import SwiftUI
import Foundation

enum AppPage3Filter: String, CaseIterable, Identifiable {
    case all = "全部临期"
    case expired = "已过期"
    case soon = "30天内"

    var id: String { rawValue }
}

struct AppPage3View: View {
    @EnvironmentObject var store: AppMedicineStore
    @State private var searchText = ""
    @State private var selectedFilter: AppPage3Filter = .all
    @State private var selectedCategory = "全部"
    @State private var ignoredIDs: Set<UUID> = []
    @State private var showAddAlert = false

    var body: some View {
        NavigationStack {
            List {
                AppPage3SummaryCard(medicines: filteredMedicines)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                Section("筛选与搜索") {
                    TextField("搜索药名、分类或位置", text: $searchText)
                        .textFieldStyle(.roundedBorder)

                    Picker("范围", selection: $selectedFilter) {
                        ForEach(AppPage3Filter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("分类", selection: $selectedCategory) {
                        Text("全部").tag("全部")
                        ForEach(store.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    if filteredMedicines.isEmpty {
                        AppPage3EmptyState(hasIgnored: !ignoredIDs.isEmpty, showAddAlert: $showAddAlert, resetAction: resetFilters)
                        .frame(maxWidth: .infinity, minHeight: 260)
                    } else {
                        ForEach(filteredMedicines) { medicine in
                            AppPage3Row(medicine: medicine)
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        withAnimation {
                                            ignoredIDs.insert(medicine.id)
                                        }
                                    } label: {
                                        Label("忽略", systemImage: "bell.slash")
                                    }
                                    .tint(.orange)
                                }
                        }
                    }
                } header: {
                    Text(headerTitle)
                }
            }
            .navigationTitle("临期提醒")
            .contentMargins(.bottom, 96, for: .scrollContent)
            .alert("添加药品", isPresented: $showAddAlert) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text("请在「添加一盒药」标签页登记新的药品。")
            }
        }
    }

    var filteredMedicines: [AppMedicine] {
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let rangeEnd = calendar.date(byAdding: .day, value: 30, to: today) ?? today.addingTimeInterval(30 * 24 * 3600)

        return store.medicines
            .filter { !ignoredIDs.contains($0.id) }
            .filter { medicine in
                let expiry = calendar.startOfDay(for: medicine.expiryDate)
                switch selectedFilter {
                case .all:
                    return expiry <= rangeEnd
                case .expired:
                    return expiry < today
                case .soon:
                    return expiry >= today && expiry <= rangeEnd
                }
            }
            .filter { medicine in
                selectedCategory == "全部" || medicine.category == selectedCategory
            }
            .filter { medicine in
                if searchText.isEmpty { return true }
                return medicine.name.localizedCaseInsensitiveContains(searchText) ||
                    medicine.category.localizedCaseInsensitiveContains(searchText) ||
                    medicine.location.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.expiryDate < $1.expiryDate }
    }

    private var headerTitle: String {
        if filteredMedicines.isEmpty {
            return "提醒列表"
        }
        return "提醒列表 · \(filteredMedicines.count) 种药"
    }

    private func resetFilters() {
        withAnimation {
            searchText = ""
            selectedFilter = .all
            selectedCategory = "全部"
            ignoredIDs.removeAll()
        }
    }
}

struct AppPage3SummaryCard: View {
    let medicines: [AppMedicine]

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("临期总览")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                AppPage3StatTile(
                    title: "临期药盒",
                    value: "\(medicines.reduce(0) { $0 + $1.quantity })",
                    unit: "盒"
                )

                AppPage3StatTile(
                    title: "最早到期",
                    value: nearestExpiryText,
                    unit: ""
                )

                AppPage3StatTile(
                    title: "7天内",
                    value: "\(within7DaysCount)",
                    unit: "盒"
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.vertical, 8)
    }

    private var nearestExpiryText: String {
        guard let date = medicines.min(by: { $0.expiryDate < $1.expiryDate })?.expiryDate else {
            return "—"
        }
        return Self.dateFormatter.string(from: date)
    }

    private var within7DaysCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 7, to: today) ?? today

        return medicines
            .filter { medicine in
                let expiry = calendar.startOfDay(for: medicine.expiryDate)
                return expiry >= today && expiry <= end
            }
            .reduce(0) { $0 + $1.quantity }
    }
}

struct AppPage3StatTile: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AppPage3Row: View {
    let medicine: AppMedicine

    private static let expiryFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(medicine.name)
                    .font(.headline)

                Spacer()

                AppPage3Badge(days: daysUntilExpiry)
            }

            HStack(spacing: 12) {
                Label("\(medicine.category) · \(medicine.specification)", systemImage: "pills")
                Label(medicine.location, systemImage: "location")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Label("\(medicine.quantity) \(medicine.unit)", systemImage: "number.square")

                if medicine.isOpened {
                    Label("已开封", systemImage: "checkmark.circle")
                        .foregroundStyle(.blue)
                }

                Spacer()

                Text(expiryText)
                    .font(.caption)
                    .foregroundStyle(isExpired ? .red : .orange)
            }
        }
        .padding(.vertical, 4)
    }

    private var daysUntilExpiry: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiry = calendar.startOfDay(for: medicine.expiryDate)
        return calendar.dateComponents([.day], from: today, to: expiry).day ?? 0
    }

    private var isExpired: Bool {
        daysUntilExpiry < 0
    }

    private var expiryText: String {
        Self.expiryFormatter.string(from: medicine.expiryDate)
    }
}

struct AppPage3Badge: View {
    let days: Int

    var body: some View {
        if days < 0 {
            Text("已过期\(-days)天")
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.15), in: Capsule())
                .foregroundStyle(.red)
        } else if days <= 7 {
            Text("\(days)天后到期")
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15), in: Capsule())
                .foregroundStyle(.orange)
        } else {
            Text("\(days)天后到期")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.15), in: Capsule())
                .foregroundStyle(.yellow)
        }
    }
}

struct AppPage3EmptyState: View {
    let hasIgnored: Bool
    @Binding var showAddAlert: Bool
    let resetAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)

            Text("没有临期药品")
                .font(.headline)

            Text("30天内到期的药品会显示在这里。如果刚刚筛选过，试试重置筛选。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if hasIgnored {
                Button("恢复已忽略", action: resetAction)
                    .buttonStyle(.bordered)
            } else {
                Button("去添加药品") {
                    showAddAlert = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 260)
    }
}