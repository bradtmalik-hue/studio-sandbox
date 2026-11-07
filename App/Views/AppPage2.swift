import SwiftUI
import Foundation

struct AppWaterRecord: Identifiable, Codable {
    let id: UUID
    var date: Date
    var amount: Double
    var note: String
}

struct AppPage2DayGroup: Identifiable {
    let id: Date
    let records: [AppWaterRecord]
}

struct AppPage2View: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            content
        }
    }

    private var filteredRecords: [AppWaterRecord] {
        if searchText.isEmpty {
            return store.records
        }
        return store.records.filter {
            $0.note.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedDays: [AppPage2DayGroup] {
        let grouped = Dictionary(grouping: filteredRecords) {
            Calendar.current.startOfDay(for: $0.date)
        }
        return grouped
            .map { day, records in
                AppPage2DayGroup(id: day, records: records)
            }
            .sorted { $0.id > $1.id }
    }

    var content: some View {
        Group {
            if filteredRecords.isEmpty {
                emptyState
            } else {
                recordList
            }
        }
        .navigationTitle("历史")
        .searchable(text: $searchText, prompt: "搜索备注")
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("暂无饮水记录", systemImage: "drop")
        } description: {
            Text("点击下方按钮快速添加一杯水")
        } actions: {
            Button("添加第一条") {
                addSampleRecord()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var recordList: some View {
        List {
            summaryHeader
            ForEach(groupedDays) { group in
                NavigationLink(destination: AppPage2DayDetailView(day: group.id, records: group.records)) {
                    AppPage2DayRow(day: group.id, records: group.records)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        deleteDay(group.id)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
        .contentMargins(.bottom, 96, for: .scrollContent)
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("共 \(filteredRecords.count) 条记录")
                .font(.headline)
            HStack {
                Text("合计 \(String(format: "%.0f", filteredRecords.reduce(0) { $0 + $1.amount })) 毫升")
                Spacer()
                if let recent = filteredRecords.map(\.date).max() {
                    Text("最近 \(Self.dateFormatter.string(from: recent))")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func addSampleRecord() {
        let record = AppWaterRecord()
        store.records.append(record)
        saveStore()
    }

    private func deleteDay(_ day: Date) {
        store.records.removeAll {
            Calendar.current.isDate($0.date, inSameDayAs: day)
        }
        saveStore()
    }

    private func saveStore() {
        let data = AppPersistedData(records: store.records, dailyGoal: store.dailyGoal)
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: store.fileURL)
        } catch {
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()
}

struct AppPage2DayRow: View {
    let day: Date
    let records: [AppWaterRecord]

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.dayFormatter.string(from: day))
                    .font(.headline)
                Text("\(records.count) 条记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("\(String(format: "%.0f", records.reduce(0) { $0 + $1.amount })) 毫升")
                .font(.headline)
        }
        .padding(.vertical, 4)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEE"
        return formatter
    }()
}

struct AppPage2DayDetailView: View {
    @EnvironmentObject var store: AppStore
    let day: Date
    let records: [AppWaterRecord]

    var body: some View {
        List {
            Section {
                HStack {
                    Text("合计")
                    Spacer()
                    Text("\(String(format: "%.0f", records.reduce(0) { $0 + $1.amount })) 毫升")
                        .fontWeight(.semibold)
                }
            }
            ForEach(sortedRecords) { record in
                AppPage2RecordRow(record: record)
                    .swipeActions {
                        Button(role: .destructive) {
                            deleteRecord(record)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
        }
        .navigationTitle(Self.dayFormatter.string(from: day))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sortedRecords: [AppWaterRecord] {
        records.sorted { $0.date > $1.date }
    }

    private func deleteRecord(_ record: AppWaterRecord) {
        store.records.removeAll { $0.id == record.id }
        saveStore()
    }

    private func saveStore() {
        let data = AppPersistedData(records: store.records, dailyGoal: store.dailyGoal)
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: store.fileURL)
        } catch {
        }
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter
    }()
}

struct AppPage2RecordRow: View {
    let record: AppWaterRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.timeFormatter.string(from: record.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.body)
                }
            }
            Spacer()
            Text("\(String(format: "%.0f", record.amount)) 毫升")
                .font(.headline)
        }
        .padding(.vertical, 4)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}