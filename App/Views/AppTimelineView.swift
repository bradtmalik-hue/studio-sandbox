import SwiftUI
import Foundation

struct AppTimelineView: View {
    @EnvironmentObject var store: AppQuoteStore
    @State private var selectedDay: Date? = nil
    
    private var availableDays: [Date] {
        let days = Set(store.quotes.map { Calendar.current.startOfDay(for: $0.recordDate) })
        return days.sorted(by: >)
    }
    
    private var daySections: [DaySection] {
        let grouped = Dictionary(grouping: store.quotes) { Calendar.current.startOfDay(for: $0.recordDate) }
        return grouped.map { DaySection(date: $0.key, quotes: $0.value) }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        Group {
            if store.quotes.isEmpty {
                emptyState
            } else {
                mainContent
            }
        }
        .navigationTitle("时间线")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            dayChips
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            List {
                if let selectedDay = selectedDay {
                    let filteredQuotes = quotes(for: selectedDay)
                    ForEach(filteredQuotes.indices, id: \.self) { index in
                        quoteRow(filteredQuotes[index])
                    }
                } else {
                    ForEach(daySections) { section in
                        Section(header: Text(dayTitle(section.date))) {
                            ForEach(section.quotes.indices, id: \.self) { index in
                                quoteRow(section.quotes[index])
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text("还没有摘录")
                .font(.title2)
                .fontWeight(.semibold)
            Text("去“记一句”添加你的第一条摘录，\n它们会按日期出现在这里。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var dayChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                DayChip(title: "全部", isSelected: selectedDay == nil) {
                    selectedDay = nil
                }
                ForEach(availableDays, id: \.self) { day in
                    DayChip(title: chipTitle(day), isSelected: selectedDay == day) {
                        selectedDay = day
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func quotes(for day: Date) -> [AppQuote] {
        store.quotes.filter { Calendar.current.isDate($0.recordDate, inSameDayAs: day) }
            .sorted { $0.recordDate > $1.recordDate }
    }
    
    private func quoteRow(_ quote: AppQuote) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(quote.text)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            HStack {
                Text(quote.bookTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("第\(quote.pageNumber)页")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let note = quote.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
    
    private func chipTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEE"
        return formatter.string(from: date)
    }
    
    private func dayTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 EEEE"
        return formatter.string(from: date)
    }
}

private struct DaySection: Identifiable {
    let date: Date
    let quotes: [AppQuote]
    var id: Date { date }
}

private struct DayChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green.opacity(0.2) : Color(.systemGray6))
                .foregroundColor(isSelected ? .green : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}