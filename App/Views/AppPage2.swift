import SwiftUI
import Combine

struct AppPage2View: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var selectedBookTitle: String? = nil
    @State private var showingAddSheet = false

    private var sortedQuotes: [AppQuote] {
        store.quotes.sorted { $0.createdAt > $1.createdAt }
    }

    private var filteredQuotes: [AppQuote] {
        var result = sortedQuotes
        if let book = selectedBookTitle, !book.isEmpty {
            result = result.filter { $0.bookTitle == book }
        }
        if !searchText.isEmpty {
            result = result.filter { quote in
                quote.bookTitle.localizedCaseInsensitiveContains(searchText) ||
                quote.author.localizedCaseInsensitiveContains(searchText) ||
                quote.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    private var uniqueBookTitles: [String] {
        Array(Set(store.quotes.map { $0.bookTitle })).sorted()
    }

    private var totalQuotes: Int {
        store.quotes.count
    }

    private var uniqueBooksCount: Int {
        uniqueBookTitles.count
    }

    private var latestDateText: String {
        guard let latest = sortedQuotes.first?.createdAt else { return "暂无" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: latest)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage2SummaryCard(
                        totalQuotes: totalQuotes,
                        uniqueBooks: uniqueBooksCount,
                        latestDate: latestDateText
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section {
                    if filteredQuotes.isEmpty {
                        AppPage2EmptyView(
                            hasFilter: !searchText.isEmpty || selectedBookTitle != nil,
                            onAdd: { showingAddSheet = true },
                            onClearFilter: {
                                searchText = ""
                                selectedBookTitle = nil
                            }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(filteredQuotes) { quote in
                            NavigationLink(destination: AppPage2DetailView(quote: quote)) {
                                AppPage2Row(quote: quote)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteQuote(quote)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("摘录列表")
            .searchable(text: $searchText, prompt: "搜索书名、作者或内容")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("全部") {
                            selectedBookTitle = nil
                        }
                        ForEach(uniqueBookTitles, id: \.self) { title in
                            Button(title) {
                                selectedBookTitle = title
                            }
                        }
                    } label: {
                        Label("筛选", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AppPage2AddSheet()
            }
        }
    }

    func deleteQuote(_ quote: AppQuote) {
        store.quotes.removeAll { $0.id == quote.id }
    }
}

struct AppPage2SummaryCard: View {
    let totalQuotes: Int
    let uniqueBooks: Int
    let latestDate: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("摘录概览")
                .font(.headline)
                .foregroundColor(.secondary)
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("\(totalQuotes)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("条摘录")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("\(uniqueBooks)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("本书")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text(latestDate)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("最近摘录")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct AppPage2Row: View {
    let quote: AppQuote

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: quote.createdAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(quote.bookTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(dateText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 8) {
                Text(quote.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("·")
                    .foregroundColor(.secondary)
                Text("第 \(quote.pageNumber) 页")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Text(quote.content)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 4)
    }
}

struct AppPage2EmptyView: View {
    let hasFilter: Bool
    let onAdd: () -> Void
    let onClearFilter: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(hasFilter ? "未找到匹配摘录" : "还没有摘录", systemImage: hasFilter ? "magnifyingglass" : "book.closed")
        } description: {
            Text(hasFilter ? "试试调整搜索或筛选条件" : "记录下每本书里打动你的那句话")
        } actions: {
            if hasFilter {
                Button("清除筛选", action: onClearFilter)
            } else {
                Button("添加第一条", action: onAdd)
            }
        }
    }
}

struct AppPage2DetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore
    let quote: AppQuote

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: quote.createdAt)
    }

    var body: some View {
        Form {
            Section("书名") {
                Text(quote.bookTitle)
            }
            Section("作者") {
                Text(quote.author)
            }
            Section("页码") {
                Text("第 \(quote.pageNumber) 页")
            }
            Section("摘录内容") {
                Text(quote.content)
                    .lineLimit(nil)
            }
            Section("记录时间") {
                Text(dateText)
            }
            Section {
                Button(role: .destructive) {
                    store.quotes.removeAll { $0.id == quote.id }
                    dismiss()
                } label: {
                    Label("删除这条摘录", systemImage: "trash")
                }
            }
        }
        .navigationTitle("摘录详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppPage2AddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore

    @State private var bookTitle = ""
    @State private var author = ""
    @State private var pageNumberText = ""
    @State private var content = ""
    @State private var createdAt = Date()

    private var isFormValid: Bool {
        guard !bookTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let page = Int(pageNumberText), page > 0 else { return false }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("必填信息") {
                    TextField("书名", text: $bookTitle)
                    TextField("作者", text: $author)
                    TextField("页码", text: $pageNumberText)
                        .keyboardType(.numberPad)
                }
                Section("摘录内容") {
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                }
                Section("记录时间") {
                    DatePicker("时间", selection: $createdAt, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                }
            }
            .navigationTitle("新增摘录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let page = Int(pageNumberText) else { return }
                        let newQuote = AppQuote(
                            id: UUID(),
                            bookTitle: bookTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                            author: author.trimmingCharacters(in: .whitespacesAndNewlines),
                            pageNumber: page,
                            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                            createdAt: createdAt
                        )
                        store.quotes.append(newQuote)
                        dismiss()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
}