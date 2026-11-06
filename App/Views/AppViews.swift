import SwiftUI
import Combine
import Foundation

// MARK: - 本地化格式
private enum AppFormatters {
    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()

    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    static let shortDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "E"
        return formatter
    }()

    static func grams(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f 克", value)
        } else {
            return String(format: "%.1f 克", value)
        }
    }
}

// MARK: - 空状态
struct AppFeedingEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("还没有喂猫记录")
                .font(.title2.weight(.semibold))
            Text("点右上角 + 添加第一笔记录")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 96)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - 单条喂食记录行
struct AppFeedingRecordRow: View {
    let record: AppFeedingRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.mealType.rawValue)
                    .font(.headline)
                Text(AppFormatters.dateTime.string(from: record.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(AppFormatters.grams(record.amount))
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 喂食记录列表页
struct AppFeedingLogView: View {
    @EnvironmentObject var store: AppCatMealStore
    @State private var showingAddSheet = false

    private var sortedRecords: [AppFeedingRecord] {
        store.records.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedRecords.isEmpty {
                    AppFeedingEmptyView()
                } else {
                    List {
                        ForEach(sortedRecords) { record in
                            AppFeedingRecordRow(record: record)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("喂猫记录")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("添加记录", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AppAddFeedingSheet()
            }
        }
    }
}

// MARK: - 添加喂食记录弹窗
struct AppAddFeedingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppCatMealStore

    @State private var date = Date()
    @State private var amountText = ""
    @State private var mealType: AppMealType = AppMealType.allCases.first!

    private var amountValue: Double? {
        let text = amountText.trimmingCharacters(in: .whitespaces)
        guard let value = Double(text), value > 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("时间") {
                    DatePicker("喂猫时间", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("类型") {
                    Picker("食物类型", selection: $mealType) {
                        ForEach(AppMealType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                Section("食量") {
                    TextField("克数", text: $amountText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("添加记录")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { addRecord() }
                        .disabled(amountValue == nil)
                }
            }
        }
    }

    private func addRecord() {
        guard let amount = amountValue else { return }
        let record = AppFeedingRecord(date: date, amount: amount, mealType: mealType)
        store.add(record)
        dismiss()
    }
}

// MARK: - 喂食日历页
struct AppFeedingCalendarView: View {
    @EnvironmentObject var store: AppCatMealStore
    @State private var displayedMonth: Date = Calendar.current.startOfDay(for: Date())

    var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "zh_CN")
        cal.firstWeekday = 2
        return cal
    }()

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    private var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
    }

    private var daysInMonth: [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: monthStart) else { return [] }
        let days = calendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 0
        return (0..<days).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    private var leadingEmpty: Int {
        let weekday = calendar.component(.weekday, from: monthStart)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button {
                            changeMonth(-1)
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        Spacer()
                        Text(AppFormatters.monthYear.string(from: displayedMonth))
                            .font(.title2.weight(.semibold))
                        Spacer()
                        Button {
                            changeMonth(1)
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(0..<leadingEmpty, id: \.self) { _ in
                            Color.clear.frame(height: 44)
                        }
                        ForEach(daysInMonth, id: \.self) { day in
                            AppCalendarDayCell(
                                day: day,
                                isMissed: missed(on: day),
                                hasFed: !records(on: day).isEmpty,
                                isToday: calendar.isDate(day, inSameDayAs: Date())
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("喂食日历")
        }
    }

    func records(on day: Date) -> [AppFeedingRecord] {
        store.records.filter { calendar.isDate($0.date, inSameDayAs: day) }
    }

    private func missed(on day: Date) -> Bool {
        let startOfDay = calendar.startOfDay(for: day)
        let today = calendar.startOfDay(for: Date())
        if startOfDay > today { return false }
        return records(on: day).isEmpty
    }

    private func changeMonth(_ by: Int) {
        if let newDate = calendar.date(byAdding: .month, value: by, to: displayedMonth) {
            displayedMonth = newDate
        }
    }
}

// MARK: - 日历单日单元格
struct AppCalendarDayCell: View {
    let day: Date
    let isMissed: Bool
    let hasFed: Bool
    let isToday: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: day))")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if isMissed {
                Circle()
                    .fill(Color.red.opacity(0.7))
                    .frame(width: 6, height: 6)
            } else if hasFed {
                Circle()
                    .fill(Color.green.opacity(0.7))
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(height: 44)
    }

    private var backgroundColor: Color {
        if isToday { return Color.blue.opacity(0.15) }
        if isMissed { return Color.red.opacity(0.08) }
        if hasFed { return Color.green.opacity(0.08) }
        return Color.clear
    }
}

// MARK: - 统计页
struct AppFeedingSummaryView: View {
    @EnvironmentObject var store: AppCatMealStore
    private let calendar = Calendar.current

    private var totalFeedings: Int {
        store.records.count
    }

    private var totalAmount: Double {
        store.records.reduce(0) { $0 + $1.amount }
    }

    private var averageAmount: Double {
        totalFeedings == 0 ? 0 : totalAmount / Double(totalFeedings)
    }

    private var missedDays: Int {
        guard let firstDate = store.records.map({ $0.date }).min() else { return 0 }
        let start = calendar.startOfDay(for: firstDate)
        let today = calendar.startOfDay(for: Date())
        guard start <= today else { return 0 }
        var count = 0
        var day = start
        while day <= today {
            let hasFed = store.records.contains { calendar.isDate($0.date, inSameDayAs: day) }
            if !hasFed { count += 1 }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        AppStatCard(title: "总次数", value: "\(totalFeedings)", systemImage: "number.circle")
                        AppStatCard(title: "总食量", value: AppFormatters.grams(totalAmount), systemImage: "scalemass")
                    }

                    HStack(spacing: 12) {
                        AppStatCard(title: "平均每次", value: AppFormatters.grams(averageAmount), systemImage: "chart.bar")
                        AppStatCard(title: "漏喂天数", value: "\(missedDays)", systemImage: "exclamationmark.triangle")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("最近7天食量")
                            .font(.headline)
                        AppRecent7DayChart(records: store.records, calendar: calendar)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("喂食统计")
        }
    }
}

// MARK: - 统计卡片
struct AppStatCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.title2.weight(.semibold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 最近7天柱状图
struct AppRecent7DayChart: View {
    let records: [AppFeedingRecord]
    let calendar: Calendar

    private var days: [Date] {
        let today = calendar.startOfDay(for: Date())
        return Array((0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.reversed())
    }

    private func amount(for day: Date) -> Double {
        records.filter { calendar.isDate($0.date, inSameDayAs: day) }
            .reduce(0) { $0 + $1.amount }
    }

    private var maxAmount: Double {
        max(days.map { amount(for: $0) }.max() ?? 0, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(days, id: \.self) { day in
                VStack(spacing: 6) {
                    Text(AppFormatters.shortDay.string(from: day))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.gradient)
                        .frame(height: CGFloat(amount(for: day) / maxAmount) * 100)
                    Text(String(format: "%.0f", amount(for: day)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 160)
    }
}