import SwiftUI
import Foundation

private enum AppPage1Format {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    static func string(from date: Date) -> String {
        dateFormatter.string(from: date)
    }
}

struct AppPage1View: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var filterMode = 0
    @State private var showingAddBook = false
    @State private var showingAddExcerpt = false

    private var filteredBooks: [AppBook] {
        let sorted = store.books.sorted { $0.lastReadAt > $1.lastReadAt }
        return sorted.filter { book in
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                if !book.title.lowercased().contains(query) && !book.author.lowercased().contains(query) {
                    return false
                }
            }
            let progress = Double(book.currentPage) / Double(max(book.totalPages, 1))
            switch filterMode {
            case 1:
                return progress < 1
            case 2:
                return progress >= 1
            default:
                return true
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !store.books.isEmpty {
                    Section {
                        AppPage1SummaryCard(books: store.books)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    Section {
                        Picker("筛选", selection: $filterMode) {
                            Text("全部").tag(0)
                            Text("在读").tag(1)
                            Text("读完").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                if !store.books.isEmpty {
                    Section {
                        if filteredBooks.isEmpty {
                            AppPage1EmptyFilterView()
                        } else {
                            ForEach(filteredBooks) { book in
                                NavigationLink(destination: AppPage1BookDetailView(book: book)) {
                                    AppPage1BookRow(book: book)
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        deleteBook(book)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("在读的书")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索书名或作者")
            .navigationTitle("正在读的书")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddBook = true
                    } label: {
                        Label("添加书", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddExcerpt = true
                    } label: {
                        Label("加摘录", systemImage: "quote.bubble")
                    }
                }
            }
            .overlay {
                if store.books.isEmpty {
                    ContentUnavailableView {
                        Label("还没有在读的书", systemImage: "books.vertical")
                    } description: {
                        Text("点击右上角 + 添加第一本书，或先添加一条摘录。")
                    } actions: {
                        Button("添加第一本书") {
                            showingAddBook = true
                        }
                        .buttonStyle(.borderedProminent)

                        Button("添加摘录") {
                            showingAddExcerpt = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
        .sheet(isPresented: $showingAddBook) {
            AppPage1AddBookView()
        }
        .sheet(isPresented: $showingAddExcerpt) {
            AppPage1AddExcerptView()
        }
    }

    private func deleteBook(_ book: AppBook) {
        store.books.removeAll { $0.id == book.id }
    }
}

struct AppPage1SummaryCard: View {
    let books: [AppBook]

    private var totalCurrentPages: Int {
        books.reduce(0) { $0 + $1.currentPage }
    }

    private var lastReadDate: Date? {
        books.map(\.lastReadAt).max()
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                AppPage1StatView(value: "\(books.count)", unit: "本", title: "总共")
                Spacer()
                AppPage1StatView(value: "\(totalCurrentPages)", unit: "页", title: "已读")
                Spacer()
                AppPage1StatView(value: lastReadDate.map { AppPage1Format.string(from: $0) } ?? "—", unit: "", title: "最近阅读")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

struct AppPage1StatView: View {
    let value: String
    let unit: String
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AppPage1BookRow: View {
    let book: AppBook

    var progress: Double {
        Double(book.currentPage) / Double(max(book.totalPages, 1))
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                Text(book.author)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text("\(book.currentPage) / \(book.totalPages) 页")
                    Text("·")
                    Text(AppPage1Format.string(from: book.lastReadAt))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(progress >= 1 ? Color.green : Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(progress * 100))%")
                    .font(.caption2.bold())
            }
            .frame(width: 44, height: 44)
        }
        .padding(.vertical, 4)
    }
}

struct AppPage1EmptyFilterView: View {
    var body: some View {
        ContentUnavailableView {
            Label("没有符合条件的书", systemImage: "magnifyingglass")
        } description: {
            Text("换个筛选条件或搜索词试试。")
        }
    }
}

struct AppPage1AddBookView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var author = ""
    @State private var currentPage = 0
    @State private var totalPages = 300
    @State private var startDate = Date()
    @State private var lastReadAt = Date()
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("书籍信息") {
                    TextField("书名", text: $title)
                    TextField("作者", text: $author)
                }
                Section("进度") {
                    Stepper("当前页：\(currentPage)", value: $currentPage, in: 0...max(totalPages, currentPage))
                    Stepper("总页数：\(totalPages)", value: $totalPages, in: max(currentPage, 1)...9999)
                }
                Section("日期") {
                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                    DatePicker("最近阅读", selection: $lastReadAt, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("添加书")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
                        let trimmedAuthor = author.trimmingCharacters(in: .whitespaces)
                        if trimmedTitle.isEmpty {
                            errorMessage = "书名不能为空"
                            showError = true
                            return
                        }
                        if totalPages <= 0 {
                            errorMessage = "总页数必须大于 0"
                            showError = true
                            return
                        }
                        if currentPage > totalPages {
                            errorMessage = "当前页不能超过总页数"
                            showError = true
                            return
                        }
                        let book = AppBook(
                            id: UUID(),
                            title: trimmedTitle,
                            author: trimmedAuthor,
                            currentPage: currentPage,
                            totalPages: totalPages,
                            startDate: startDate,
                            lastReadAt: lastReadAt
                        )
                        store.books.append(book)
                        dismiss()
                    }
                }
            }
            .alert("无法保存", isPresented: $showError) {
                Button("好", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

struct AppPage1AddExcerptView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedBookID: UUID?
    @State private var bookTitleManual = ""
    @State private var pageNumber = 1
    @State private var content = ""
    @State private var createdAt = Date()
    @State private var showError = false
    @State private var errorMessage = ""

    private var selectedBookTitle: String {
        guard let selectedBookID,
              let book = store.books.first(where: { $0.id == selectedBookID }) else {
            return ""
        }
        return book.title
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("书") {
                    if store.books.isEmpty {
                        Text("请先添加一本书，或输入书名")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("选择书", selection: $selectedBookID) {
                            Text("选择一本书").tag(nil as UUID?)
                            ForEach(store.books) { book in
                                Text(book.title).tag(Optional(book.id))
                            }
                        }
                    }
                    if selectedBookID == nil || store.books.isEmpty {
                        TextField("书名", text: $bookTitleManual)
                    }
                }
                Section("摘录") {
                    Stepper("页码：\(pageNumber)", value: $pageNumber, in: 1...9999)
                    TextField("内容", text: $content, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("时间") {
                    DatePicker("记录时间", selection: $createdAt, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("加摘录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmedContent.isEmpty {
                            errorMessage = "摘录内容不能为空"
                            showError = true
                            return
                        }
                        let excerpt = AppExcerpt(
                            id: UUID(),
                            bookID: selectedBookID,
                            text: trimmedContent,
                            createdAt: createdAt
                        )
                        store.excerpts.append(excerpt)
                        dismiss()
                    }
                }
            }
            .alert("无法保存", isPresented: $showError) {
                Button("好", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if selectedBookID == nil, let firstBook = store.books.first {
                    selectedBookID = firstBook.id
                }
            }
        }
    }
}

struct AppPage1BookDetailView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let book: AppBook

    @State private var title: String
    @State private var author: String
    @State private var currentPage: Int
    @State private var totalPages: Int
    @State private var startDate: Date
    @State private var lastReadAt: Date

    @State private var hasChanges = false
    @State private var showCancelAlert = false
    @State private var showError = false
    @State private var errorMessage = ""

    init(book: AppBook) {
        self.book = book
        _title = State(initialValue: book.title)
        _author = State(initialValue: book.author)
        _currentPage = State(initialValue: book.currentPage)
        _totalPages = State(initialValue: book.totalPages)
        _startDate = State(initialValue: book.startDate)
        _lastReadAt = State(initialValue: book.lastReadAt)
    }

    private var progress: Double {
        Double(currentPage) / Double(max(totalPages, 1))
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        totalPages > 0 &&
        currentPage >= 0 &&
        currentPage <= totalPages
    }

    var body: some View {
        Form {
            Section("书籍信息") {
                TextField("书名", text: $title)
                    .onChange(of: title) { _ in hasChanges = true }
                TextField("作者", text: $author)
                    .onChange(of: author) { _ in hasChanges = true }
            }
            Section("进度") {
                Stepper("当前页：\(currentPage)", value: $currentPage, in: 0...max(totalPages, currentPage))
                    .onChange(of: currentPage) { _ in hasChanges = true }
                Stepper("总页数：\(totalPages)", value: $totalPages, in: max(currentPage, 1)...9999)
                    .onChange(of: totalPages) { _ in hasChanges = true }
                HStack {
                    Text("进度")
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .foregroundStyle(progress >= 1 ? .green : .primary)
                }
            }
            Section("日期") {
                DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                    .onChange(of: startDate) { _ in hasChanges = true }
                DatePicker("最近阅读", selection: $lastReadAt, displayedComponents: [.date, .hourAndMinute])
                    .onChange(of: lastReadAt) { _ in hasChanges = true }
            }
        }
        .navigationTitle("书籍详情")
        .navigationBarTitleDisplayMode(.inline)
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
                    let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
                    let trimmedAuthor = author.trimmingCharacters(in: .whitespaces)
                    if trimmedTitle.isEmpty {
                        errorMessage = "书名不能为空"
                        showError = true
                        return
                    }
                    if totalPages <= 0 {
                        errorMessage = "总页数必须大于 0"
                        showError = true
                        return
                    }
                    if currentPage > totalPages {
                        errorMessage = "当前页不能超过总页数"
                        showError = true
                        return
                    }
                    if let index = store.books.firstIndex(where: { $0.id == book.id }) {
                        store.books[index] = AppBook(
                            id: book.id,
                            title: trimmedTitle,
                            author: trimmedAuthor,
                            currentPage: currentPage,
                            totalPages: totalPages,
                            startDate: startDate,
                            lastReadAt: lastReadAt
                        )
                    }
                    dismiss()
                }
                .disabled(!isValid || !hasChanges)
            }
        }
        .alert("放弃更改？", isPresented: $showCancelAlert) {
            Button("继续编辑", role: .cancel) { }
            Button("放弃", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("有未保存的更改。")
        }
        .alert("无法保存", isPresented: $showError) {
            Button("好", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}