import SwiftUI
import Foundation

struct AppPage1View: View {
    @EnvironmentObject var store: AppStore
    @State private var bookTitle = ""
    @State private var author = ""
    @State private var pageNumberText = ""
    @State private var content = ""
    @State private var showSavedAlert = false
    @State private var validationMessage: String?

    var pageNumber: Int {
        Int(pageNumberText) ?? 0
    }

    private var isValid: Bool {
        let title = bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let quoteContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return !title.isEmpty && !quoteContent.isEmpty && pageNumber > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    AppPage1Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("书摘本", systemImage: "text.book.closed.fill")
                                .font(.headline)
                            Text("记下每本书里打动你的那句话")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("书籍信息") {
                    TextField("书名", text: $bookTitle)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.next)
                    TextField("作者", text: $author)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                    HStack {
                        Text("页码")
                        Spacer()
                        TextField("第几页", text: $pageNumberText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 96)
                    }
                }

                Section("摘录内容") {
                    TextEditor(text: $content)
                        .frame(minHeight: 140)
                        .overlay(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("例如：'我们终此一生，就是要摆脱他人的期待，找到真正的自己。'")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section {
                    Button {
                        saveQuote()
                    } label: {
                        HStack {
                            Spacer()
                            Label("保存摘录", systemImage: "square.and.arrow.down.fill")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(!isValid)
                } footer: {
                    if let validationMessage {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    } else {
                        Text("书名、页码和摘录内容为必填。")
                    }
                }
            }
            .navigationTitle("录一条摘录")
            .alert("已保存", isPresented: $showSavedAlert) {
                Button("好", role: .cancel) { }
            } message: {
                Text("这条摘录已经收进你的书摘本。")
            }
        }
    }

    private func saveQuote() {
        validationMessage = nil

        let title = bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let quoteContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty, !quoteContent.isEmpty, pageNumber > 0 else {
            validationMessage = "请填写书名、页码和摘录内容。"
            return
        }

        let quote = AppQuote(
            id: UUID(),
            bookTitle: title,
            author: author.trimmingCharacters(in: .whitespacesAndNewlines),
            pageNumber: pageNumber,
            content: quoteContent,
            createdAt: Date()
        )

        store.quotes.append(quote)
        store.save()

        bookTitle = ""
        author = ""
        pageNumberText = ""
        content = ""
        showSavedAlert = true
    }
}

struct AppPage1Card<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}

struct AppPage1EmptyState: View {
    var body: some View {
        ContentUnavailableView(
            "还没有摘录",
            systemImage: "text.quote",
            description: Text("先写一条，记录下书里最打动你的那句话。")
        )
    }
}