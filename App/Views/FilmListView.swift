import SwiftUI

struct FilmListView: View {
    @EnvironmentObject var store: AppFilmLibraryStore
    @State private var searchText = ""
    @State private var editingRecord: AppFilmRecord?

    var filteredRecords: [AppFilmRecord] {
        let sorted = store.records.sorted { $0.watchDate > $1.watchDate }
        if searchText.isEmpty {
            return sorted
        } else {
            return sorted.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredRecords.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredRecords) { record in
                            Button {
                                editingRecord = record
                            } label: {
                                FilmListRow(record: record)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(record)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("观影列表")
            .searchable(text: $searchText, prompt: "搜索片名")
            .sheet(item: $editingRecord) { record in
                NavigationStack {
                    FilmDetailEditView(record: record)
                        .environmentObject(store)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("还没有电影记录")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("去“记一部”添加第一部看过的电影吧")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func delete(_ record: AppFilmRecord) {
        store.delete(record)
    }
}

private struct FilmListRow: View {
    let record: AppFilmRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(.headline)
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= record.starRating ? "star.fill" : "star")
                            .foregroundStyle(index <= record.starRating ? .yellow : .gray)
                            .font(.caption)
                    }
                }
                Text(record.watchDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
}