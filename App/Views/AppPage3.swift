import SwiftUI

enum AppPage3Filter: CaseIterable, Identifiable {
    case all
    case dueSoon
    case overdue
    case upcoming

    var id: Self { self }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .dueSoon:
            return "即将到期"
        case .overdue:
            return "已逾期"
        case .upcoming:
            return "未来"
        }
    }
}

struct AppPage3MetricView: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(color)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct AppPage3SummaryCard: View {
    let reminders: [AppReminder]
    let upcomingCount: Int

    var body: some View {
        HStack(spacing: 12) {
            AppPage3MetricView(
                title: "总提醒",
                value: "\(reminders.count)",
                unit: "条",
                color: .blue
            )
            AppPage3MetricView(
                title: "即将到期",
                value: "\(upcomingCount)",
                unit: "条",
                color: .orange
            )
        }
        .padding(.vertical, 4)
    }
}

struct AppPage3Row: View {
    let reminder: AppReminder
    let daysRemaining: Int

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.petName)
                    .font(.headline)
                Text(reminder.vaccineName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(reminder.dueDate, style: .date)
                    .font(.subheadline)
                Text(daysRemainingText)
                    .font(.caption)
                    .foregroundColor(daysRemaining < 0 ? .red : .secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var daysRemainingText: String {
        if daysRemaining < 0 {
            return "逾期 \(-daysRemaining) 天"
        }
        if daysRemaining == 0 {
            return "今天到期"
        }
        return "\(daysRemaining) 天后"
    }
}

struct AppPage3Empty: View {
    let hasReminders: Bool
    let searchText: String

    var body: some View {
        if hasReminders {
            ContentUnavailableView.search(text: searchText)
        } else {
            ContentUnavailableView("暂无提醒", systemImage: "bell.slash", description: Text("暂时没有需要关注的疫苗提醒。"))
        }
    }
}

struct AppPage3View: View {
    let result: [AppReminder]
    let calendar: Calendar
    let today: Date
    let days: Int

    @State private var filter: AppPage3Filter = .all
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if result.isEmpty {
                    AppPage3Empty(hasReminders: false, searchText: searchText)
                } else {
                    reminderList
                }
            }
            .navigationTitle("疫苗提醒")
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("筛选", selection: $filter) {
                        ForEach(AppPage3Filter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private var filteredReminders: [AppReminder] {
        var reminders = result
        if !searchText.isEmpty {
            reminders = reminders.filter {
                $0.petName.localizedCaseInsensitiveContains(searchText) ||
                    $0.vaccineName.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch filter {
        case .all:
            return reminders
        case .dueSoon:
            return reminders.filter { $0.daysRemaining >= 0 && $0.daysRemaining <= days }
        case .overdue:
            return reminders.filter { $0.daysRemaining < 0 }
        case .upcoming:
            return reminders.filter { $0.daysRemaining > days }
        }
    }

    private var reminderList: some View {
        List {
            Section {
                AppPage3SummaryCard(
                    reminders: result,
                    upcomingCount: result.filter { $0.daysRemaining >= 0 && $0.daysRemaining <= days }.count
                )
            }

            Section("提醒列表") {
                ForEach(filteredReminders) { reminder in
                    AppPage3Row(reminder: reminder, daysRemaining: reminder.daysRemaining)
                }
            }
        }
        .overlay {
            if filteredReminders.isEmpty {
                AppPage3Empty(hasReminders: true, searchText: searchText)
            }
        }
    }
}
