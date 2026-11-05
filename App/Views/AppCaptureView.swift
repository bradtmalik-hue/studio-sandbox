import SwiftUI

struct AppCaptureView: View {
    @EnvironmentObject private var store: AppQuoteStore
    @Environment(\.dismiss) private var dismiss
    @State private var bookTitle = ""
    @State private var pageNumber = ""
    @State private var quoteText = ""
    @State private var note = ""
    @State private var showValidationAlert = false

    private let ink = Color(red: 0.05, green: 0.25, blue: 0.22)
    private let paper = Color.white

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("书名", text: $bookTitle)
                    TextField("页码", text: $pageNumber)
                        .keyboardType(.numberPad)
                    TextField("句子原文", text: $quoteText, axis: .vertical)
                        .lineLimit(4...8)
                    TextField("感想（可选）", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("摘录内容")
                } footer: {
                    Text("书名、页码和句子原文为必填项。")
                }

                Section {
                    Button {
                        saveQuote()
                    } label: {
                        Text("保存摘录")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .disabled(!isFormValid)
                }
                .listRowBackground(ink.opacity(0.1))
            }
            .scrollContentBackground(.hidden)
            .background(paper)
            .navigationTitle("记一句")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .alert("信息不完整", isPresented: $showValidationAlert) {
                Button("好", role: .cancel) { }
            } message: {
                Text("请填写书名、页码和句子原文。页码需为数字。")
            }
        }
    }

    private var isFormValid: Bool {
        !bookTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !pageNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(pageNumber.trimmingCharacters(in: .whitespacesAndNewlines)) != nil &&
        !quoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveQuote() {
        let trimmedBook = bookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPage = pageNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedQuote = quoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedBook.isEmpty,
              Int(trimmedPage) != nil,
              !trimmedQuote.isEmpty else {
            showValidationAlert = true
            return
        }

        let quote = AppQuote(bookTitle: trimmedBook,
                             pageNumber: trimmedPage,
                             quoteText: trimmedQuote,
                             note: trimmedNote,
                             createdAt: Date())
        store.add(quote)
        dismiss()
    }
}