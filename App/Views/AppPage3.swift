import SwiftUI

struct AppPage3View: View {
    @EnvironmentObject var store: AppHydrationStore
    @State private var selectedDays: Int = 7
    @State private var showGoalLine = true
    @State private var showValues = true
    
    var calendar: Calendar { Calendar.current }
    
    private var startDate: Date {
        calendar.date(byAdding: .day, value: -(selectedDays - 1), to: calendar.startOfDay(for: Date())) ?? Date()
    }
    
    private var periodRecords: [AppWaterRecord] {
        store.records.filter { $0.date >= startDate }
    }
    
    private var dailyAmounts: [Date: Double] {
        Dictionary(grouping: periodRecords, by: { calendar.startOfDay(for: $0.date) })
            .mapValues { records in records.reduce(0) { $0 + $1.amount } }
    }
    
    private var dailyData: [AppPage3DailyTotal] {
        let days = (0..<selectedDays).compactMap { calendar.date(byAdding: .day, value: $0, to: startDate) }
        return days.map { day in
            AppPage3DailyTotal()
        }
    }
    
    private var totalInPeriod: Double {
        dailyData.reduce(0) { $0 + $1.amount }
    }
    
    private var averageInPeriod: Double {
        totalInPeriod / Double(selectedDays)
    }
    
    private var metGoalDays: Int {
        dailyData.filter { $0.amount >= 2000 }.count
    }
    
    private var recentRecords: [AppWaterRecord] {
        Array(periodRecords.sorted { $0.date > $1.date }.prefix(7))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    VStack {
                        controls
                        AppPage3EmptyState()
                        Spacer()
                    }
                    .padding()
                } else {
                    VStack(spacing: 0) {
                        controls
                        List {
                            Section {
                                summaryCards
                                AppPage3BarChart(dailyData: dailyData, showGoalLine: showGoalLine, showValues: showValues)
                            }
                            Section("最近记录") {
                                if recentRecords.isEmpty {
                                    Text("所选周期内没有记录")
                                        .foregroundStyle(.secondary)
                                } else {
                                    ForEach(recentRecords) { record in
                                        AppPage3RecordRow(record: record)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                        .background(Color(red: 0.94, green: 0.96, blue: 0.99))
                        .contentMargins(.bottom, 96, for: .scrollContent)
                    }
                }
            }
            .navigationTitle("统计")
            .background(Color(red: 0.94, green: 0.96, blue: 0.99))
        }
    }
    
    private var controls: some View {
        VStack(spacing: 12) {
            Picker("统计周期", selection: $selectedDays) {
                Text("7天").tag(7)
                Text("30天").tag(30)
            }
            .pickerStyle(.segmented)
            
            HStack {
                Toggle("显示达标线", isOn: $showGoalLine)
                Toggle("显示数值", isOn: $showValues)
            }
            .font(.subheadline)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var summaryCards: some View {
        HStack(spacing: 12) {
            AppPage3SummaryCard(title: "日均", value: String(format: "%.0f", averageInPeriod), unit: "毫升", icon: "drop.fill", tint: .blue)
            AppPage3SummaryCard(title: "达标", value: "\(metGoalDays)", unit: "天", icon: "checkmark.circle.fill", tint: .green)
            AppPage3SummaryCard(title: "总量", value: String(format: "%.0f", totalInPeriod), unit: "毫升", icon: "sum", tint: .cyan)
        }
        .padding(.vertical, 4)
    }
}

struct AppPage3DailyTotal: Identifiable {
    var id: Date { date }
    let date: Date
    let amount: Double
}

struct AppPage3SummaryCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let tint: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct AppPage3BarChart: View {
    let dailyData: [AppPage3DailyTotal]
    let showGoalLine: Bool
    let showValues: Bool
    
    private let chartHeight: CGFloat = 160
    private let goal: Double = 2000
    
    private var maxValue: Double {
        max(goal, dailyData.map(\.amount).max() ?? 0) * 1.1
    }
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(dailyData) { item in
                        VStack(spacing: 2) {
                            if showValues {
                                Text("\(Int(item.amount))")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColor(amount: item.amount))
                                .frame(height: max(4, CGFloat(item.amount / maxValue) * chartHeight))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: chartHeight, alignment: .bottom)
                
                if showGoalLine {
                    Rectangle()
                        .fill(Color.red.opacity(0.5))
                        .frame(height: 1)
                        .offset(y: -CGFloat(goal / maxValue) * chartHeight)
                        .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }
            .frame(height: chartHeight)
            
            HStack(spacing: 6) {
                ForEach(dailyData) { item in
                    Text(shortDate(item.date))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func barColor(amount: Double) -> Color {
        amount >= goal ? Color.green : Color.blue
    }
    
    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M/d"
        return f.string(from: date)
    }
}

struct AppPage3RecordRow: View {
    let record: AppWaterRecord
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .foregroundStyle(.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(record.amount, specifier: "%.0f") 毫升")
                    .font(.headline)
                Text(record.container)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(formattedDate(record.date))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 HH:mm"
        return f.string(from: date)
    }
}

struct AppPage3EmptyState: View {
    var body: some View {
        ContentUnavailableView("暂无饮水记录", systemImage: "drop.circle", description: Text("记录每天的饮水后，这里会显示趋势和达标情况"))
    }
}