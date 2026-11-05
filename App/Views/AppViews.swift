import SwiftUI
import Combine
import Foundation

struct AppCheckInView: View {
    @EnvironmentObject var store: AppStore
    @State private var practiceDate = Date()
    @State private var duration: Double = 30
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("每天记录练琴时长")
                            .font(.headline)
                        Text("坚持打卡，一个月后你会看到进步")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("练习日期") {
                    DatePicker("日期", selection: $practiceDate, displayedComponents: .date)
                }

                Section("练习时长") {
                    Stepper("\(Int(duration)) 分钟", value: $duration, in: 1...300, step: 5)
                    Slider(value: $duration, in: 1...300, step: 5) {
                        Text("时长")
                    } minimumValueLabel: {
                        Text("1")
                    } maximumValueLabel: {
                        Text("300")
                    }
                }

                Section("备注") {
                    TextField("例如：哈农、音阶、练习曲", text: $note)
                }

                Section {
                    Button {
                        let record = AppPracticeRecord(
                            date: practiceDate,
                            durationMinutes: duration,
                            note: note,
                            records: [],
                            fileURL: store.fileURL
                        )
                        store.add(record)
                        note = ""
                        duration = 30
                    } label: {
                        Text("保存打卡")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("打卡")
        }
    }
}

struct AppRecordsView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedMonth = Date()

    private var filteredRecords: [AppPracticeRecord] {
        store.records.filter { record in
            Calendar.current.isDate(record.date, equalTo: selectedMonth, toGranularity: .month)
        }
        .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Picker("月份", selection: $selectedMonth) {
                    ForEach(-12..<1, id: \.self) { offset in
                        let month = Calendar.current.date(byAdding: .month, value: offset, to: Date())!
                        Text(month, format: .dateTime.year().month())
                            .tag(month)
                    }
                }
                .pickerStyle(.menu)
                .padding()

                if filteredRecords.isEmpty {
                    ContentUnavailableView(
                        "这个月还没有打卡记录",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("去打卡页面记录你的第一次练习吧")
                    )
                } else {
                    List {
                        ForEach(filteredRecords, id: \.id) { record in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(record.date, format: .dateTime.month().day().weekday())
                                        .font(.headline)
                                    if !record.note.isEmpty {
                                        Text(record.note)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text("\(Int(record.durationMinutes)) 分钟")
                                    .font(.subheadline)
                                    .monospacedDigit()
                            }
                        }
                        .onDelete { offsets in
                            let recordsToDelete = offsets.map { filteredRecords[$0] }
                            for record in recordsToDelete {
                                if let index = store.records.firstIndex(where: { $0.id == record.id }) {
                                    store.records.remove(at: index)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("记录")
        }
    }
}

struct AppStatisticsView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedMonth = Date()

    private var monthRecords: [AppPracticeRecord] {
        store.records.filter { record in
            Calendar.current.isDate(record.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var totalDuration: Double {
        monthRecords.reduce(0.0) { $0 + $1.durationMinutes }
    }

    private var totalCount: Int {
        monthRecords.count
    }

    private var averageDuration: Double {
        guard totalCount > 0 else { return 0 }
        return totalDuration / Double(totalCount)
    }

    private var daysInMonth: [Date] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: selectedMonth)!
        let days = calendar.dateComponents([.day], from: interval.start, to: interval.end).day!
        return (0..<days).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    private func durationForDay(_ day: Date) -> Double {
        let calendar = Calendar.current
        return monthRecords
            .filter { calendar.isDate($0.date, inSameDayAs: day) }
            .reduce(0.0) { $0 + $1.durationMinutes }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("月份", selection: $selectedMonth) {
                        ForEach(-12..<1, id: \.self) { offset in
                            let month = Calendar.current.date(byAdding: .month, value: offset, to: Date())!
                            Text(month, format: .dateTime.year().month())
                                .tag(month)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()

                    if monthRecords.isEmpty {
                        ContentUnavailableView(
                            "这个月还没有练琴记录",
                            systemImage: "chart.bar.xaxis",
                            description: Text("开始打卡后，这里会展示你的进步")
                        )
                    } else {
                        HStack(spacing: 16) {
                            AppStatCard(title: "总时长", value: "\(Int(totalDuration)) 分钟", systemImage: "clock")
                            AppStatCard(title: "打卡次数", value: "\(totalCount) 次", systemImage: "checkmark.circle")
                            AppStatCard(title: "平均时长", value: "\(Int(averageDuration)) 分钟", systemImage: "chart.bar")
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading) {
                            Text("每日练习时长")
                                .font(.headline)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .bottom, spacing: 4) {
                                    ForEach(daysInMonth, id: \.self) { day in
                                        let duration = durationForDay(day)
                                        VStack {
                                            Text("\(Int(duration))")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            Capsule()
                                                .fill(duration > 0 ? Color.accentColor : Color.gray.opacity(0.3))
                                                .frame(width: 10, height: min(max(4, CGFloat(duration) * 0.8), 120))
                                            Text(day, format: .dateTime.day())
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 180)
                        }
                        .padding(.vertical)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("统计")
        }
    }
}

struct AppStatCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.tint)
            Text(value)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}