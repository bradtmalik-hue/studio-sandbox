import SwiftUI
import Foundation

private enum AppPage2Format {
    static let excerptDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()
}

struct AppPage2View: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var selectedBookID: UUID?
    @State private var showingAddSheet = false
    @State private var detailExcerpt: AppExcerpt?

    private var sortedExcerpts: [AppExcerpt] {
        store.excerpts.sorted { $0.createdAt > $1.createdAt }
    }

    private var filteredExcerpts: [AppExcerpt] {
        sortedExcerpts.filter { excerpt in
            let bookTitle = store.books.first(where: { $0.id == excerpt.selectedBookID })?.title ?? ""
            let matchesSearch = searchText.isEmpty ||
                excerpt.text.localizedCaseInsensitiveContains(searchText) ||
                bookTitle.localizedCaseInsensitiveContains(searchText) ||
                excerpt.note.localizedCaseInsensitiveContains(searchText)
            let matchesBook = selectedBookID == nil || excerpt.selectedBookID == selectedBookID
            return matchesSearch && matchesBook
        }
    }

    private var recentDateText: String {
        guard let first = filteredExcerpts.first else { return "暂无" }
        return AppPage2Format.excerptDateFormatter.string(from: first.createdAt)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage2SummaryCard(
                        filteredCount: filteredExcerpts.count,
                        totalCount: store.excerpts.count,
                        recentDate: recentDateText
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section {
                    AppPage2FilterChips(selectedBookID: $selectedBookID, books: store.books)
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("搜索摘录、书名或笔记", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                }

                if filteredExcerpts.isEmpty {
                    ContentUnavailableView {
                        Label("暂无摘录", systemImage: "text.quote")
                    } description: {
                        Text(searchText.isEmpty ? "把想记住的句子记下来。" : "没有符合当前筛选的摘录。")
                    } actions: {
                        Button("添加第一条摘录") {
                            showingAddSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        ForEach(filteredExcerpts) { excerpt in
                            Button {
                                detailExcerpt = excerpt
                            } label: {
                                AppPage2Row(excerpt: excerpt)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button(role: .destructive) {
                                    delete(excerpt)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("摘录列表")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("添加摘录", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $detailExcerpt) { excerpt in
                AppPage2DetailView(excerpt: excerpt)
            }
            .sheet(isPresented: $showingAddSheet) {
                AppPage2AddSheet()
            }
        }
    }

    private func delete(_ excerpt: AppExcerpt) {
        store.excerpts.removeAll { $0.id == excerpt.id }
    }
}

struct AppPage2Row: View {
    @EnvironmentObject var store: AppStore
    let excerpt: AppExcerpt

    private var bookTitle: String {
        store.books.first(where: { $0.id == excerpt.selectedBookID })?.title ?? "未知书籍"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(bookTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(excerpt.text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label("第\(excerpt.pageText)页", systemImage: "book.closed")
                    Text(AppPage2Format.excerptDateFormatter.string(from: excerpt.createdAt))
                    if !excerpt.note.isEmpty {
                        Label(excerpt.note, systemImage: "pencil")
                            .lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

struct AppPage2SummaryCard: View {
    let filteredCount: Int
    let totalCount: Int
    let recentDate: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("筛选结果")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(filteredCount) 条")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("全部摘录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(totalCount) 条")
                        .font(.title3.weight(.semibold))
                }
            }

            Divider()

            HStack {
                Text("最近摘录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(recentDate)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.primary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct AppPage2FilterChips: View {
    @Binding var selectedBookID: UUID?
    let books: [AppBook]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    selectedBookID = nil
                } label: {
                    Text("全部")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedBookID == nil ? Color.accentColor : Color.secondary.opacity(0.1), in: Capsule())
                        .foregroundStyle(selectedBookID == nil ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)

                ForEach(books) { book in
                    Button {
                        selectedBookID = book.id
                    } label: {
                        Text(book.title)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedBookID == book.id ? Color.accentColor : Color.secondary.opacity(0.1), in: Capsule())
                            .foregroundStyle(selectedBookID == book.id ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct AppPage2DetailView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let originalID: UUID
    @State private var text: String
    @State private var pageText: String
    @State private var note: String
    @State private var selectedBookID: UUID?
    @State private var createdAt: Date

    init(excerpt: AppExcerpt) {
        self.originalID = excerpt.id
        _text = State(initialValue: excerpt.text)
        _pageText = State(initialValue: excerpt.pageText)
        _note = State(initialValue: excerpt.note)
        _selectedBookID = State(initialValue: excerpt.selectedBookID)
        _createdAt = State(initialValue: excerpt.createdAt)
    }

    private var pageValue: Int? {
        Int(pageText)
    }

    var isValid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        pageValue != nil && pageValue! > 0 &&
        selectedBookID != nil &&
        store.books.contains(where: { $0.id == selectedBookID })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("书籍") {
                    Menu {
                        ForEach(store.books) { book in
                            Button {
                                selectedBookID = book.id
                            } label: {
                                if selectedBookID == book.id {
                                    Label(book.title, systemImage: "checkmark")
                                } else {
                                    Text(book.title)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedBookID.flatMap { id in store.books.first(where: { $0.id == id })?.title } ?? "选择书籍")
                                .foregroundStyle(selectedBookID == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("摘录内容") {
                    TextField("摘录原文", text: $text)
                }

                Section("页码") {
                    TextField("页码", text: $pageText)
                        .keyboardType(.numberPad)
                    if pageValue == nil || pageValue! <= 0 {
                        Text("页码必须是大于 0 的数字")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("笔记") {
                    TextField("补充笔记", text: $note)
                }

                Section("摘录时间") {
                    DatePicker("摘录时间", selection: $createdAt)
                }
            }
            .navigationTitle("编辑摘录")
            .navigationBarTitleDisplayMode(.inline)
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
        guard let page = pageValue, page > 0,
              let book = store.books.first(where: { $0.id == selectedBookID }) else { return }
        let updated = AppExcerpt(
            originalID: originalID,
            text: text,
            pageText: pageText,
            note: note,
            selectedBookID: book.id,
            createdAt: createdAt
        )
        if let index = store.excerpts.firstIndex(where: { $0.id == originalID }) {
            store.excerpts[index] = updated
        }
        dismiss()
    }
}

struct AppPage2AddSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var pageText = ""
    @State private var note = ""
    @State private var selectedBookID: UUID?
    @State private var createdAt = Date()

    private var pageValue: Int? {
        Int(pageText)
    }

    var isValid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        pageValue != nil && pageValue! > 0 &&
        selectedBookID != nil &&
        store.books.contains(where: { $0.id == selectedBookID })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("书籍") {
                    if store.books.isEmpty {
                        Text("先在“正在读的书”里添加一本书")
                            .foregroundStyle(.secondary)
                    } else {
                        Menu {
                            ForEach(store.books) { book in
                                Button {
                                    selectedBookID = book.id
                                } label: {
                                    if selectedBookID == book.id {
                                        Label(book.title, systemImage: "checkmark")
                                    } else {
                                        Text(book.title)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedBookID.flatMap { id in store.books.first(where: { $0.id == id })?.title } ?? "选择书籍")
                                    .foregroundStyle(selectedBookID == nil ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("摘录内容") {
                    TextField("摘录原文", text: $text)
                }

                Section("页码") {
                    TextField("页码", text: $pageText)
                        .keyboardType(.numberPad)
                    if pageValue == nil || pageValue! <= 0 {
                        Text("页码必须是大于 0 的数字")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("笔记") {
                    TextField("补充笔记", text: $note)
                }

                Section("摘录时间") {
                    DatePicker("摘录时间", selection: $createdAt)
                }
            }
            .navigationTitle("添加摘录")
            .navigationBarTitleDisplayMode(.inline)
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
            .onAppear {
                if selectedBookID == nil {
                    selectedBookID = store.books.first?.id
                }
            }
        }
    }

    func save() {
        guard let page = pageValue, page > 0,
              let book = store.books.first(where: { $0.id == selectedBookID }) else { return }
        let excerpt = AppExcerpt(
            originalID: UUID(),
            text: text,
            pageText: pageText,
            note: note,
            selectedBookID: book.id,
            createdAt: createdAt
        )
        store.excerpts.append(excerpt)
        dismiss()
    }
}