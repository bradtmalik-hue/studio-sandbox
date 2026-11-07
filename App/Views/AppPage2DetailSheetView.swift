import SwiftUI

struct AppPage2DetailSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("项目名称", systemImage: "tag")
                    Label("日期", systemImage: "calendar")
                    Label("金额", systemImage: "yensign")
                } header: {
                    Text("详情")
                }
            }
            .navigationTitle("详情")
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