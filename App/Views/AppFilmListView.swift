import SwiftUI
import Foundation

struct AppFilmListView: View {
    @EnvironmentObject var store: AppFilmStore
    @State private var editingRecord: AppFilmRecord?
    @State private var randomTitle: String = ""
    @State private var showRandomAlert: Bool = false

    private var groupedRecords: [(month: Date, records: [AppFilmRecord])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.films) { record -> Date in
            let components = calendar.dateComponents([.year, .month], from: record.watchDate)
            return calendar.date(from: components) ?? record.watchDate
        }
        return grouped.keys.sorted(by: >).map { month in
            (month: month, records: grouped[month]!.sorted(by: { $0.watchDate > $1.watchDate }))
        }
    }

    var body: some View {
        SwiftUI.NavigationView {
            Group {
                if store.films.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
            .navigationTitle("观影列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        pickRandom()
                    } label: {
                        Label("随机重温", systemImage: "shuffle")
                    }
                }
            }
            .sheet(item: $editingRecord) { record in
                AppFilmEditorView()
                    .environmentObject(store)
            }
            .alert("随机重温", isPresented: $showRandomAlert) {
                Button("好的", role: .cancel) { }
            } message: {
                Text(randomTitle)
            }
        }
    }

    private var listView: some View {
        List {
            ForEach(groupedRecords, id: \.month) { group in
                Section(header: Text(monthString(from: group.month))) {
                    ForEach(group.records) { record in
                        Button {
                            editingRecord = record
                        } label: {
                            row(for: record)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func row(for record: AppFilmRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    AppStarRatingView()
                    Text(String(format: "%.1f", record.rating))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text(record.watchDate, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("还没有观影记录")
                .font(.headline)
            Text("点击下方“记一部”开始记录你看过的电影")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func pickRandom() {
        guard let random = store.films.randomElement() else {
            randomTitle = "暂无记录"
            showRandomAlert = true
            return
        }
        randomTitle = random.title
        showRandomAlert = true
    }

    private func monthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }
}