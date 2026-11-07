import SwiftUI

private let excerptDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M月d日 HH:mm"
    return formatter
}()

struct AppPage2View: View {
    @EnvironmentObject var store: AppStore
    
    @State private var searchText = ""
    @State private var selectedBookFilter = "全部"
    @State private var showAddSheet = false
    @State private var selectedExcerpt: AppExcerpt?
    
    private var filteredExcerpts: [AppExcerpt] {
        let sorted = store.excerpts.sorted { $0.createdAt > $1.createdAt }
        return sorted.filter { excerpt in
            let matchesSearch = searchText.isEmpty ||
                excerpt.content.localizedCaseInsensitiveContains(searchText) ||
                excerpt.bookTitle.localizedCaseInsensitiveContains(searchText)
            let matchesBook = selectedBookFilter == "全部" || excerpt.bookTitle == selectedBookFilter
            return matchesSearch && matchesBook
        }
    }
    
    private var totalCharacters: Int {
        store.excerpts.reduce(0) { $0 + $1.content.count }
    }
    
    private var recentExcerptText: String {
        guard let latest = store.excerpts.max(by: { $0.createdAt < $1.createdAt }) else { return "—" }
        return excerptDateFormatter.string(from: latest.createdAt)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    summaryCard
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                Section {
                    TextField("搜索摘录内容或书名", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    Picker("筛选书籍", selection: $selectedBookFilter) {
                        Text("全部").tag("全部")
                        ForEach(store.books.map(\.title), id: \.self) { title in
                            Text(title).tag(title)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                if !filteredExcerpts.isEmpty {
                    Section {
                        ForEach(filteredExcerpts, id: \.id) { excerpt in
                            AppPage2Row(excerpt: excerpt)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedExcerpt = excerpt
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        store.excerpts.removeAll { $0.id == excerpt.id }
                                        store.save()
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("摘录列表")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Label("添加", systemImage: "plus")
                    }
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .overlay {
                if filteredExcerpts.isEmpty {
                    if store.excerpts.isEmpty {
                        ContentUnavailableView {
                            Label("暂无摘录", systemImage: "quote.bubble")
                        } description: {
                            Text("添加摘录后，这里会按时间倒序显示。")
                        } actions: {
                            Button("添加第一篇摘录") {
                                showAddSheet = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        ContentUnavailableView {
                            Label("没有匹配的摘录", systemImage: "magnifyingglass")
                        } description: {
                            Text("换个关键词或筛选条件试试。")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AppPage2AddSheet()
                    .environmentObject(store)
            }
            .sheet(isPresented: Binding(
                get: { selectedExcerpt != nil },
                set: { if !$0 { selectedExcerpt = nil } }
            )) {
                if let selectedExcerpt = selectedExcerpt {
                    AppPage2DetailSheet(excerpt: selectedExcerpt)
                }
            }
        }
    }
    
    private var summaryCard: some View {
        HStack(alignment: .top, spacing: 16) {
            metricBlock(value: "\(store.excerpts.count)", label: "条摘录")
            Spacer()
            metricBlock(value: "\(totalCharacters)", label: "累计字数")
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text(recentExcerptText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text("最近记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func metricBlock(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AppPage2Row: View {
    let excerpt: AppExcerpt
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(excerpt.bookTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("第 \(excerpt.pageNumber) 页")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }
                Text(excerpt.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                HStack {
                    Spacer()
                    Text(excerptDateFormatter.string(from: excerpt.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct AppPage2DetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let excerpt: AppExcerpt
    
    var body: some View {
        NavigationStack {
            Form {
                Section("摘录内容") {
                    Text(excerpt.content)
                        .padding(.vertical, 4)
                }
                Section("书籍信息") {
                    LabeledContent("书名", value: excerpt.bookTitle)
                    LabeledContent("页码", value: "第 \(excerpt.pageNumber) 页")
                    LabeledContent("记录时间", value: excerptDateFormatter.string(from: excerpt.createdAt))
                }
            }
            .navigationTitle("摘录详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AppPage2AddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore
    
    @State private var bookTitle = ""
    @State private var pageNumber = ""
    @State private var content = ""
    
    private var validationMessage: String? {
        if bookTitle.isEmpty {
            return "请选择一本书。"
        }
        if pageNumber.isEmpty {
            return "请输入页码。"
        }
        guard let page = Int(pageNumber), page > 0 else {
            return "页码必须是大于 0 的数字。"
        }
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "摘录内容不能为空。"
        }
        return nil
    }
    
    private var canSave: Bool {
        validationMessage == nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("书籍") {
                    Picker("书名", selection: $bookTitle) {
                        ForEach(store.books.map(\.title), id: \.self) { title in
                            Text(title).tag(title)
                        }
                    }
                    .onAppear {
                        if bookTitle.isEmpty, let first = store.books.first?.title {
                            bookTitle = first
                        }
                    }
                }
                Section("页码") {
                    TextField("页码", text: $pageNumber)
                        .keyboardType(.numberPad)
                }
                Section("摘录内容") {
                    TextField("写下摘录…", text: $content, axis: .vertical)
                        .lineLimit(3...6)
                }
                if let validationMessage = validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundColor(.red)
                    }
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
                        guard canSave else { return }
                        let newExcerpt = AppExcerpt(
                            id: UUID(),
                            bookTitle: bookTitle,
                            pageNumber: Int(pageNumber) ?? 1,
                            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                            createdAt: Date()
                        )
                        store.excerpts.append(newExcerpt)
                        store.save()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}