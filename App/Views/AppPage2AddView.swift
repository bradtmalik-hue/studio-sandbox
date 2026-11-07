import SwiftUI

struct AppPage2AddView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var isFavorite = false

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(amount) != nil && (Double(amount) ?? 0) > 0
    }

    var body: some View {
        Form {
            Section {
                TextField("名称", text: $title)
                TextField("金额", text: $amount)
                    .keyboardType(.decimalPad)
                DatePicker("日期", selection: $date, displayedComponents: .date)
                Toggle("收藏", isOn: $isFavorite)
                TextField("备注", text: $note)
            }
            Section {
                Button("保存") {
                    dismiss()
                }
                .disabled(!canSave)
            }
        }
        .navigationTitle("添加记录")
        .navigationBarTitleDisplayMode(.inline)
    }
}