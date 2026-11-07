import SwiftUI

struct AppPage1BookDetailView: View {
    @State private var title: String = "示例书籍"
    @State private var author: String = "张三"
    @State private var category: String = "文学"
    @State private var rating: Double = 4.5
    @State private var isFinished: Bool = false
    @State private var readDate: Date = Date()
    @State private var notes: String = "这是一段示例笔记"

    var body: some View {
        Form {
            Section("书籍信息") {
                TextField("书名", text: $title)
                TextField("作者", text: $author)
                TextField("分类", text: $category)
            }
            Section("阅读状态") {
                Toggle("已读完", isOn: $isFinished)
                DatePicker("阅读日期", selection: $readDate, displayedComponents: .date)
            }
            Section("评分") {
                Slider(value: $rating, in: 0...5, step: 0.5)
                Text("评分: \(rating, specifier: "%.1f")")
            }
            Section("笔记") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle("书籍详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}