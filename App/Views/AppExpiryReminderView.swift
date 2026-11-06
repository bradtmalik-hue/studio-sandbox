import Foundation
import SwiftUI

private struct AppExpiryItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var expiryDate: Date
}

struct AppExpiryReminderView: View {
    @State private var items: [AppExpiryItem] = []
    @State private var showingAdd = false

    private var isChinese: Bool {
        Locale.preferredLanguages.first?.hasPrefix("zh") ?? false
    }

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("expiryReminders.json")
    }

    private var sortedItems: [AppExpiryItem] {
        items.sorted { $0.expiryDate < $1.expiryDate }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView {
                        Label(
                            isChinese ? "没有临期提醒" : "No Expiry Reminders",
                            systemImage: "clock.badge.exclamationmark"
                        )
                    } description: {
                        Text(isChinese ? "点击右上角添加物品和到期时间" : "Tap the plus button to add an item and its expiry date.")
                    }
                } else {
                    List {
                        ForEach(sortedItems) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)
                                    Text(formattedExpiry(item.expiryDate))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(dayText(item.expiryDate))
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(dayColor(item.expiryDate).opacity(0.2))
                                    .foregroundStyle(dayColor(item.expiryDate))
                                    .clipShape(Capsule())
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle(isChinese ? "临期提醒" : "Expiry Reminders")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(isChinese ? "添加提醒" : "Add Reminder")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AppAddReminderSheet { name, date in
                    items.append(AppExpiryItem(id: UUID(), name: name, expiryDate: date))
                    save()
                }
            }
            .onAppear {
                load()
            }
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([AppExpiryItem].self, from: data) else {
            return
        }
        items = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: fileURL)
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    private func daysLeft(_ date: Date) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let targetStart = Calendar.current.startOfDay(for: date)
        return Calendar.current.dateComponents([.day], from: startOfDay, to: targetStart).day ?? 0
    }

    private func dayText(_ date: Date) -> String {
        let days = daysLeft(date)
        if days < 0 {
            return isChinese ? "已过期" : "Expired"
        }
        if days == 0 {
            return isChinese ? "今天到期" : "Due today"
        }
        if days == 1 {
            return isChinese ? "明天到期" : "Due tomorrow"
        }
        return isChinese ? "剩余 \(days) 天" : "\(days) days left"
    }

    private func dayColor(_ date: Date) -> Color {
        let days = daysLeft(date)
        if days < 0 {
            return .red
        }
        if days <= 1 {
            return .orange
        }
        return .green
    }

    private func formattedExpiry(_ date: Date) -> String {
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

private struct AppAddReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    let onSave: (String, Date) -> Void

    private var isChinese: Bool {
        Locale.preferredLanguages.first?.hasPrefix("zh") ?? false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(isChinese ? "名称" : "Name", text: $name)
                    DatePicker(
                        isChinese ? "到期时间" : "Expiry Date",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }
            .navigationTitle(isChinese ? "新增提醒" : "New Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isChinese ? "取消" : "Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isChinese ? "保存" : "Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed, date)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}