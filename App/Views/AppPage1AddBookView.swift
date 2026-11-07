import SwiftUI
import Foundation

struct AppPage1AddBookView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var author: String = ""
    @State private var category: String = "文学"
    @State private var publishedDate = Date()
    @State private var pages: Int = 0
    @State private var isRead: Bool = false
    @State private var rating: Double = 3.0

    private let categories = ["文学", "科幻", "历史", "科技", "艺术"]

    var body: some View {
        NavigationStack {
            Form {
                Section("书籍信息") {
                    TextField("书名", text: $title)
                    TextField("作者", text: $author)
                    Picker("分类", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    DatePicker("出版日期", selection: $publishedDate, displayedComponents: .date)
                }
                Section("阅读信息") {
                    Stepper(value: $pages, in: 0...20000, step: 1) {
                        HStack {
                            Text("页数")
                            Spacer()
                            Text("\(pages)")
                        }
                    }
                    Toggle("已读", isOn: $isRead)
                    VStack(alignment: .leading) {
                        Text("评分: \(rating, specifier: "%.1f")")
                        Slider(value: $rating, in: 0...5, step: 0.5)
                    }
                }
            }
            .navigationTitle("添加书籍")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || author.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let book: [String: Any] = [
            "title": title,
            "author": author,
            "category": category,
            "publishedDate": publishedDate.timeIntervalSince1970,
            "pages": pages,
            "isRead": isRead,
            "rating": rating
        ]
        var books = loadBooks()
        books.append(book)
        persist(books)
        dismiss()
    }

    private func loadBooks() -> [[String: Any]] {
        let url = Self.booksFileURL
        guard let data = try? Data(contentsOf: url),
              let raw = try? JSONSerialization.jsonObject(with: data),
              let array = raw as? [[String: Any]] else {
            return []
        }
        return array
    }

    private func persist(_ books: [[String: Any]]) {
        let url = Self.booksFileURL
        guard let data = try? JSONSerialization.data(withJSONObject: books, options: [.prettyPrinted]) else { return }
        try? data.write(to: url)
    }

    private static var booksFileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("AppBooks.json")
    }
}