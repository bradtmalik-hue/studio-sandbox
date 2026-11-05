import SwiftUI
import Foundation

struct AppCalendarView: View {
    @EnvironmentObject var store: AppGrowthStore
    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date = Date()

    private let calendar = Calendar.current
    private let accentColor = Color(red: 0.0, green: 0.4, blue: 0.3)

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    monthHeader
                    daysOfWeekHeader
                    monthGrid
                    selectedDateRecords
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("成长日历")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            selectedDate = Date()
            displayedMonth = Date()
        }
    }

    private var monthHeader: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(accentColor)
            }
            Spacer()
            Text(monthYearString(from: displayedMonth))
                .font(.title2.bold())
                .foregroundColor(.primary)
            Spacer()
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(accentColor)
            }
        }
        .padding(.horizontal)
    }

    private var daysOfWeekHeader: some View {
        let days = ["日", "一", "二", "三", "四", "五", "六"]
        return HStack {
            ForEach(days, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        let days = daysInMonth(displayedMonth)
        let leadingSpaces = firstWeekdayOfMonth(displayedMonth) - 1
        let totalSlots = leadingSpaces + days.count
        let rows = Int(ceil(Double(totalSlots) / 7.0))

        return VStack(spacing: 4) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col
                        if index >= leadingSpaces && index < totalSlots {
                            let day = days[index - leadingSpaces]
                            dayCell(day: day)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity, minHeight: 40)
                        }
                    }
                }
            }
        }
    }

    private func dayCell(day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let hasRecords = hasRecords(on: day)

        return Button(action: { selectedDate = day }) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.body)
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 36, height: 36)
                    .background(isSelected ? accentColor : (hasRecords ? accentColor.opacity(0.2) : Color.clear))
                    .clipShape(Circle())
                if hasRecords {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }

    private var selectedDateRecords: some View {
        let records = records(on: selectedDate)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedDateString(from: selectedDate))
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            if records.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("这一天还没有成长记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("点击下方 + 记录身高体重")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(records) { record in
                    recordCard(record)
                }
            }
        }
    }

    private func recordCard(_ record: AppGrowthRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("身高")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f cm", record.height))
                    .font(.title3.bold())
                    .foregroundColor(.primary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("体重")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.2f kg", record.weight))
                    .font(.title3.bold())
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newDate
        }
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: date)
    }

    private func selectedDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: date)
    }

    private func daysInMonth(_ date: Date) -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: date) else { return [] }
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }

    private func firstWeekdayOfMonth(_ date: Date) -> Int {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        return calendar.component(.weekday, from: startOfMonth)
    }

    private func hasRecords(on date: Date) -> Bool {
        !records(on: date).isEmpty
    }

    private func records(on date: Date) -> [AppGrowthRecord] {
        store.records.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
}