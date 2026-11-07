import SwiftUI

struct AppPage1AddExcerptView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var pageNumber = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("标题", text: $title)
                    TextField("页码（可选）", text: $pageNumber)
                        .keyboardType(.numberPad)
                    TextEditor(text: $content)
                        .frame(minHeight: 160)
                } header: {
                    Text("新摘录")
                }

                Section {
                    Button("保存") {
                        dismiss()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
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
            }
        }
    }
}