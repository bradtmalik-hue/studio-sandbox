import SwiftUI

struct AppCaptureView: View {
    @EnvironmentObject var store: AppStore

    @State private var quoteText = ""
    @State private var bookTitle = ""
    @State private var author = ""
    @State private var pageText = ""
    @State private var note = ""
    @State private var showingEmptyAlert = false
    @State private var showingSavedAlert = false

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case quote
        case bookTitle
        case author
        case page
        case note
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("句子") {
                    TextEditor(text: $quoteText)
                        .focused($focusedField, equals: .quote)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if quoteText.isEmpty {
                                Text("读到好句子，随手记一句")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section("出处") {
                    TextField("书名", text: $bookTitle)
                        .focused($focusedField, equals: .bookTitle)
                    TextField("作者", text: $author)
                        .focused($focusedField, equals: .author)
                    TextField("页码", text: $pageText)
                        .focused($focusedField, equals: .page)
                        .keyboardType(.numberPad)
                }

                Section("笔记（可选）") {
                    TextEditor(text: $note)
                        .focused($focusedField, equals: .note)
                        .frame(minHeight: 80)
                }

                Section {
                    Button {
                        saveQuote()
                    } label: {
                        Text("保存句子")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("记一句")
            .alert("句子内容不能为空", isPresented: $showingEmptyAlert) {
                Button("好", role: .cancel) { }
            }
            .alert("已保存", isPresented: $showingSavedAlert) {
                Button("好", role: .cancel) { }
            } message: {
                Text("这句已放进你的书架")
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        focusedField = nil
                    }
                }
            }
        }
    }

    private func saveQuote() {
        let trimmedQuote = quoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuote.isEmpty else {
            showingEmptyAlert = true
            return
        }

        let trimmedBookTitle = bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPage = pageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let page = Int(trimmedPage) ?? 0

        let newQuote = AppQuote(
            text: trimmedQuote,
            bookTitle: trimmedBookTitle,
            author: trimmedAuthor,
            page: page,
            note: trimmedNote
        )

        store.add(newQuote)

        quoteText = ""
        bookTitle = ""
        author = ""
        pageText = ""
        note = ""
        showingSavedAlert = true
    }
}

struct AppBookshelfView: View {
    @EnvironmentObject var store: AppStore

    private struct AppBookGroup: Identifiable {
        let id: String
        let title: String
        let author: String
        let count: Int
    }

    private var groups: [AppBookGroup] {
        let grouped = Dictionary(grouping: store.quotes) { quote in
            quote.bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return grouped.keys.compactMap { rawTitle in
            let displayTitle = rawTitle.isEmpty ? "未命名书籍" : rawTitle
            guard let quotes = grouped[rawTitle] else { return nil }
            let author = quotes.first?.author ?? ""
            return AppBookGroup(
                id: displayTitle,
                title: displayTitle,
                author: author,
                count: quotes.count
            )
        }
        .sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.quotes.isEmpty {
                    ContentUnavailableView(
                        "书架还空着",
                        systemImage: "books.vertical",
                        description: Text("保存句子后，书名会自动出现在这里")
                    )
                } else {
                    List {
                        ForEach(groups) { group in
                            NavigationLink {
                                AppBookQuotesView(bookTitle: group.title)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(group.title)
                                        .font(.headline)
                                    Text(group.author.isEmpty ? "未知作者" : group.author)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("\(group.count) 句")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("书架")
        }
    }
}

struct AppBookQuotesView: View {
    @EnvironmentObject var store: AppStore

    let bookTitle: String

    private var quotes: [AppQuote] {
        if bookTitle == "未命名书籍" {
            return store.quotes.filter {
                $0.bookTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        } else {
            return store.quotes.filter { $0.bookTitle == bookTitle }
        }
    }

    var body: some View {
        List {
            ForEach(quotes) { quote in
                VStack(alignment: .leading, spacing: 8) {
                    Text(quote.text)
                        .font(.body)

                    if !quote.note.isEmpty {
                        Text(quote.note)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        if !quote.author.isEmpty {
                            Text(quote.author)
                        }
                        if quote.page > 0 {
                            Text("第 \(quote.page) 页")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(bookTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppSearchView: View {
    @EnvironmentObject var store: AppStore

    @State private var searchText = ""

    private var filteredQuotes: [AppQuote] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return store.quotes
        }

        return store.quotes.filter { quote in
            quote.text.localizedCaseInsensitiveContains(trimmed) ||
            quote.bookTitle.localizedCaseInsensitiveContains(trimmed) ||
            quote.author.localizedCaseInsensitiveContains(trimmed) ||
            quote.note.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredQuotes.isEmpty {
                    ContentUnavailableView(
                        "没有找到相关句子",
                        systemImage: "magnifyingglass",
                        description: Text("换个关键词试试")
                    )
                } else {
                    List {
                        ForEach(filteredQuotes) { quote in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(quote.text)
                                    .font(.body)

                                HStack {
                                    Text(quote.bookTitle)
                                    if !quote.author.isEmpty {
                                        Text("· \(quote.author)")
                                    }
                                    if quote.page > 0 {
                                        Text("· 第 \(quote.page) 页")
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)

                                if !quote.note.isEmpty {
                                    Text(quote.note)
                                        .font(.callout)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索句子、书名或作者")
            .navigationTitle("搜索")
        }
    }
}