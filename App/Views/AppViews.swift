import SwiftUI
import Foundation

struct TodayView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingAddSheet = false

    private var today: Date { Date() }

    private var todayRecords: [AppFeedingRecord] {
        store.records.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private var totalAmount: Double {
        todayRecords.map(\.amount).reduce(0, +)
    }

    private var targetAmount: Double {
        store.settings.dailyTarget
    }

    private var hasMetTarget: Bool {
        totalAmount >= targetAmount
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("今日喂食")
                                .font(.title2.bold())
                            Spacer()
                            Text("目标 \(targetAmount, specifier: "%.0f") g")
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: min(totalAmount / targetAmount, 1.0))
                            .tint(.orange)
                        HStack {
                            Text("已喂 \(totalAmount, specifier: "%.0f") g")
                                .font(.headline)
                            Spacer()
                            if hasMetTarget {
                                Label("已达标", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Text("还差 \(targetAmount - totalAmount, specifier: "%.0f") g")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

                    if todayRecords.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "cat")
                                .font(.system(size: 40))
                                .foregroundStyle(.orange)
                            Text("今天还没有喂食记录")
                                .font(.headline)
                            Text("点击下方按钮，记录第一笔喂食吧")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("今日记录")
                                .font(.headline)
                            ForEach(todayRecords) { record in
                                HStack {
                                    Label(record.date, format: .dateTime.hour().minute())
                                    Spacer()
                                    Text("\(record.amount, specifier: "%.0f") g")
                                        .fontWeight(.medium)
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("今天")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("添加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddFeedingSheet(defaultDate: today)
                    .environmentObject(store)
            }
        }
    }
}

struct AddFeedingSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let defaultDate: Date
    @State private var feedingDate: Date = Date()
    @State private var amountText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("时间") {
                    DatePicker("喂食时间", selection: $feedingDate, displayedComponents: [.hourAndMinute, .date])
                }
                Section("克数") {
                    TextField("克数", text: $amountText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("添加喂食记录")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(Double(amountText) == nil)
                }
            }
        }
        .onAppear {
            feedingDate = defaultDate
        }
    }

    private func save() {
        guard let amount = Double(amountText), amount > 0 else { return }
        let record = AppFeedingRecord(date: feedingDate, amount: amount)
        store.add(record)
        dismiss()
    }
}

struct CalendarView: View {
    @EnvironmentObject var store: AppStore
    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date = Date()

    private let calendar = Calendar.current

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.year().month(.wide))
    }

    private var daysWithLeadingBlanks: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let days = calendar.dateComponents([.day], from: monthInterval.start, to: monthInterval.end).day ?? 0
        let startOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let leadingEmpty = (firstWeekday - calendar.firstWeekday + 7) % 7
        var result: [Date?] = Array(repeating: nil, count: leadingEmpty)
        for day in 0..<days {
            if let date = calendar.date(byAdding: .day, value: day, to: startOfMonth) {
                result.append(date)
            }
        }
        return result
    }

    private var selectedRecords: [AppFeedingRecord] {
        store.records.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button {
                            if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
                                displayedMonth = newMonth
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                        }
                        Spacer()
                        Text(monthTitle)
                            .font(.headline)
                        Spacer()
                        Button {
                            if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
                                displayedMonth = newMonth
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                        }
                    }
                    .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(daysWithLeadingBlanks.indices, id: \.self) { index in
                            if let date = daysWithLeadingBlanks[index] {
                                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                                let hasRecord = store.records.contains { calendar.isDate($0.date, inSameDayAs: date) }
                                VStack(spacing: 4) {
                                    Text("\(calendar.component(.day, from: date))")
                                        .font(.body)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? Color.orange.opacity(0.2) : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    if hasRecord {
                                        Circle()
                                            .fill(Color.orange)
                                            .frame(width: 6, height: 6)
                                    } else {
                                        Circle()
                                            .fill(Color.clear)
                                            .frame(width: 6, height: 6)
                                    }
                                }
                                .onTapGesture {
                                    selectedDate = date
                                }
                            } else {
                                Color.clear
                                    .frame(height: 40)
                            }
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("\(selectedDate, format: .dateTime.month().day()) 的喂食记录")
                                .font(.headline)
                            Spacer()
                        }
                        if selectedRecords.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.secondary)
                                Text("这一天还没有喂食记录")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("去“今天”页面添加吧")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            ForEach(selectedRecords) { record in
                                HStack {
                                    Label(record.date, format: .dateTime.hour().minute())
                                    Spacer()
                                    Text("\(record.amount, specifier: "%.0f") g")
                                        .fontWeight(.medium)
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("日历")
            .onAppear {
                // 确保选中日期在显示月份内
                if !calendar.isDate(selectedDate, equalTo: displayedMonth, toGranularity: .month) {
                    selectedDate = displayedMonth
                }
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var targetText: String = ""
    @State private var showSavedAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("每日目标") {
                    HStack {
                        Text("目标克数")
                        Spacer()
                        TextField("克数", text: $targetText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    Text("建议成猫每日摄入 40-60 克干粮，可根据猫咪体重和活动量调整。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("保存目标") {
                        saveTarget()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.orange)
                }

                Section("关于") {
                    Label("数据仅保存在本机", systemImage: "internaldrive")
                    Label("无需网络，无需登录", systemImage: "wifi.slash")
                }
            }
            .navigationTitle("设置")
            .onAppear {
                targetText = String(format: "%.0f", store.settings.dailyTarget)
            }
            .alert("目标已保存", isPresented: $showSavedAlert) {
                Button("好", role: .cancel) { }
            }
        }
    }

    private func saveTarget() {
        guard let newTarget = Double(targetText), newTarget > 0 else { return }
        store.settings.dailyTarget = newTarget
        showSavedAlert = true
    }
}