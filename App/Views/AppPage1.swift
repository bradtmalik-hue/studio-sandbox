import SwiftUI
import Foundation

struct AppPage1View: View {
    @EnvironmentObject private var store: AppStore
    @State private var searchText: String = ""
    @State private var showingAddBook = false
    @State private var showingAddExcerpt = false
    @State private var showingBookDetail = false
    @State private var selectedBook: AppBook?

    private var filteredBooks: [AppBook] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return store.books }
        return store.books.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.author.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.books.isEmpty {
                    AppPage1EmptyBookState {
                        showingAddBook = true
                    }
                } else if filteredBooks.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        Section {
                            HStack(spacing: 12) {
                                AppPage1MetricCard(
                                    title: "在读",
                                    value: "\(filteredBooks.count)",
                                    unit: "本"
                                )
                                AppPage1MetricCard(
                                    title: "总页数",
                                    value: "\(filteredBooks.reduce(0) { $0 + $1.pages })",
                                    unit: "页"
                                )
                                AppPage1MetricCard(
                                    title: "最近阅读",
                                    value: AppPage1Format.shortDate(from: filteredBooks.compactMap(\.readDate).max()),
                                    unit: ""
                                )
                            }
                            .padding(.vertical, 4)
                        }

                        Section("书单") {
                            ForEach(filteredBooks) { book in
                                Button {
                                    selectedBook = book
                                    showingBookDetail = true
                                } label: {
                                    AppPage1BookRow(book: book)
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete(perform: deleteBooks)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "搜索书名或作者")
                    .contentMargins(.bottom, 96, for: .scrollContent)
                }
            }
            .navigationTitle("正在读的书")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddExcerpt = true
                    } label: {
                        Label("添加摘录", systemImage: "quote.bubble.plus")
                    }
                    .disabled(store.books.isEmpty)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddBook = true
                    } label: {
                        Label("添加书", systemImage: "book.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBook) {
                AppPage1AddBookView()
                    .environment(\.locale, Locale(identifier: "zh_CN"))
            }
            .sheet(isPresented: $showingAddExcerpt) {
                AppPage1AddExcerptView()
                    .environment(\.locale, Locale(identifier: "zh_CN"))
            }
            .sheet(isPresented: $showingBookDetail) {
                if let book = selectedBook {
                    AppPage1BookDetailView()
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                }
            }
            .environment(\.locale, Locale(identifier: "zh_CN"))
        }
    }

    func deleteBooks(at offsets: IndexSet) {
        let ids = offsets.map { filteredBooks[$0].id }
        let closedSet = Set(ids)
        store.books.removeAll { closedSet.contains($0.id) }
        store.excerpts.removeAll { excerpt in
            guard let selectedBookID = excerpt.selectedBookID else { return false }
            return closedSet.contains(selectedBookID)
        }
    }
}

private struct AppPage1BookRow: View {
    let book: AppBook

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.headline)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    Text(book.category)
                    Spacer()
                    Text("\(book.pages) 页")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack {
                    Text("评分 \(book.rating, specifier: "%.1f")")
                    Spacer()
                    if let readDate = book.readDate {
                        Text(AppPage1Format.shortDate(from: readDate))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct AppPage1MetricCard: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct AppPage1EmptyBookState: View {
    let onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("还没有在读的书", systemImage: "books.vertical")
        } description: {
            Text("添加一本正在读的书，记录进度和摘录。")
        } actions: {
            Button("添加第一本", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
    }
}

private enum AppPage1Format {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    static func shortDate(from date: Date?) -> String {
        guard let date else { return "暂无" }
        return dateFormatter.string(from: date)
    }
}