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
                                    title: "累计已读",
                                    value: "\(filteredBooks.reduce(0) { $0 + $1.currentPage })",
                                    unit: "页"
                                )
                                AppPage1MetricCard(
                                    title: "最近阅读",
                                    value: AppPage1Format.shortDate(from: filteredBooks.map(\.lastReadAt).max()),
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
                    AppPage1BookDetailView(book: book)
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
        store.excerpts.removeAll { closedSet.contains($0.bookID) }
        store.save()
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
                    Text("进度 \(book.currentPage)/\(book.totalPages)")
                    Spacer()
                    Text(AppPage1Format.shortDate(from: book.lastReadAt))
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                ProgressView(
                    value: Double(min(max(book.currentPage, 0), max(book.totalPages, 1))),
                    total: Double(max(book.totalPages, 1))
                )
                .tint(.blue)
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

private struct AppPage1AddBookView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var author: String = ""
    @State private var currentPage: Int = 0
    @State private var totalPages: Int = 300
    @State private var startDate: Date = Date()
    @State private var lastReadAt: Date = Date()

    var isValid: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedTitle.isEmpty &&
               !trimmedAuthor.isEmpty &&
               totalPages > 0 &&
               currentPage >= 0 &&
               currentPage <= totalPages
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("书名", text: $title)
                    TextField("作者", text: $author)
                }

                Section("阅读进度") {
                    Stepper(value: $currentPage, in: 0...9999) {
                        HStack {
                            Text("当前页")
                            Spacer()
                            Text("\(currentPage)")
                        }
                    }
                    Stepper(value: $totalPages, in: 1...9999) {
                        HStack {
                            Text("总页数")
                            Spacer()
                            Text("\(totalPages)")
                        }
                    }
                }

                Section("时间") {
                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                    DatePicker("最后阅读", selection: $lastReadAt, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("添加在读的书")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .interactiveDismissDisabled(false)
    }

    func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let newBook = AppBook(
            id: UUID(),
            title: trimmedTitle,
            author: trimmedAuthor,
            currentPage: currentPage,
            totalPages: totalPages,
            startDate: startDate,
            lastReadAt: lastReadAt
        )
        store.books.append(newBook)
        store.save()
        dismiss()
    }
}

private struct AppPage1AddExcerptView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedBookID: UUID = UUID()
    @State private var text: String = ""
    @State private var page: Int = 0
    @State private var createdAt: Date = Date()
    @State private var note: String = ""

    var isValid: Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.books.contains { $0.id == selectedBookID } &&
               !trimmedText.isEmpty &&
               page >= 0
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.books.isEmpty {
                    ContentUnavailableView {
                        Label("没有可选书目", systemImage: "book.closed")
                    } description: {
                        Text("请先添加一本正在读的书。")
                    }
                } else {
                    Form {
                        Section("关联书目") {
                            Picker("书目", selection: $selectedBookID) {
                                ForEach(store.books) { book in
                                    Text(book.title).tag(book.id)
                                }
                            }
                        }

                        Section("摘录") {
                            TextField("摘录原文", text: $text, axis: .vertical)
                                .lineLimit(3...6)
                            TextField("笔记", text: $note, axis: .vertical)
                                .lineLimit(2...4)
                        }

                        Section("位置与时间") {
                            Stepper(value: $page, in: 0...9999) {
                                HStack {
                                    Text("页码")
                                    Spacer()
                                    Text("第 \(page) 页")
                                }
                            }
                            DatePicker("记录时间", selection: $createdAt, displayedComponents: [.date, .hourAndMinute])
                        }
                    }
                    .onAppear {
                        if !store.books.contains(where: { $0.id == selectedBookID }),
                           let firstBook = store.books.first {
                            selectedBookID = firstBook.id
                        }
                    }
                }
            }
            .navigationTitle("添加摘录")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    func save() {
        guard let book = store.books.first(where: { $0.id == selectedBookID }) else {
            return
        }
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let newExcerpt = AppExcerpt(
            id: UUID(),
            bookID: book.id,
            bookTitle: book.title,
            text: trimmedText,
            page: page,
            createdAt: createdAt,
            note: note
        )
        store.excerpts.append(newExcerpt)
        store.save()
        dismiss()
    }
}

private struct AppPage1BookDetailView: View {
    let bookID: UUID

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var author: String
    @State private var currentPage: Int
    @State private var totalPages: Int
    @State private var startDate: Date
    @State private var lastReadAt: Date
    @State private var showCancelAlert = false

    init(book: AppBook) {
        self.bookID = book.id
        _title = State(initialValue: book.title)
        _author = State(initialValue: book.author)
        _currentPage = State(initialValue: book.currentPage)
        _totalPages = State(initialValue: book.totalPages)
        _startDate = State(initialValue: book.startDate)
        _lastReadAt = State(initialValue: book.lastReadAt)
    }

    private var originalBook: AppBook? {
        store.books.first { $0.id == bookID }
    }

    private var hasChanges: Bool {
        guard let originalBook else { return false }
        return title != originalBook.title ||
               author != originalBook.author ||
               currentPage != originalBook.currentPage ||
               totalPages != originalBook.totalPages ||
               startDate != originalBook.startDate ||
               lastReadAt != originalBook.lastReadAt
    }

    var isValid: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedTitle.isEmpty &&
               !trimmedAuthor.isEmpty &&
               totalPages > 0 &&
               currentPage >= 0 &&
               currentPage <= totalPages
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("书名", text: $title)
                    TextField("作者", text: $author)
                }

                Section("阅读进度") {
                    Stepper(value: $currentPage, in: 0...9999) {
                        HStack {
                            Text("当前页")
                            Spacer()
                            Text("\(currentPage)")
                        }
                    }
                    Stepper(value: $totalPages, in: 1...9999) {
                        HStack {
                            Text("总页数")
                            Spacer()
                            Text("\(totalPages)")
                        }
                    }
                    if currentPage > totalPages {
                        Label("当前页不能超过总页数", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section("时间") {
                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                    DatePicker("最后阅读", selection: $lastReadAt, displayedComponents: [.date, .hourAndMinute])
                    Button("更新为现在") {
                        lastReadAt = Date()
                    }
                }
            }
            .navigationTitle("编辑在读的书")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if hasChanges {
                            showCancelAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("放弃修改？", isPresented: $showCancelAlert) {
                Button("继续编辑", role: .cancel) { }
                Button("放弃", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("当前有未保存的修改。")
            }
        }
        .interactiveDismissDisabled(hasChanges)
    }

    func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let updatedBook = AppBook(
            id: bookID,
            title: trimmedTitle,
            author: trimmedAuthor,
            currentPage: currentPage,
            totalPages: totalPages,
            startDate: startDate,
            lastReadAt: lastReadAt
        )

        if let index = store.books.firstIndex(where: { $0.id == bookID }) {
            store.books[index] = updatedBook
        }
        store.save()
        dismiss()
    }
}

private enum AppPage1Format {
    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    private static let timeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    static func shortDate(from date: Date?) -> String {
        guard let date else { return "暂无" }
        return shortDateFormatter.string(from: date)
    }

    static func timeDate(from date: Date) -> String {
        timeDateFormatter.string(from: date)
    }
}