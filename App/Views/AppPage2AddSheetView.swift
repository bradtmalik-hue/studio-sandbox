import SwiftUI

struct AppPage2AddSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var amount: Double = 0
    @State private var date: Date = Date()
    @State private var category: String = "一般"
    @State private var isImportant: Bool = false
    @State private var note: String = ""

    private let categories = ["一般", "餐饮", "交通", "购物"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("名称", text: $title)
                    TextField("金额", value: $amount, format: .number)
                    DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Picker("分类", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    Toggle("重要", isOn: $isImportant)
                    TextField("备注", text: $note)
                } header: {
                    Text("详情")
                } footer: {
                    if amount < 0 {
                        Text("金额不能为负数")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("添加记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { dismiss() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || amount < 0)
                }
            }
        }
    }
}