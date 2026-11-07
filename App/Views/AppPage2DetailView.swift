import SwiftUI

struct AppPage2DetailView: View {
    @State private var name = "示例记录"
    @State private var amount = 0.0
    @State private var date = Date()
    @State private var category = "工作"
    @State private var isFavorite = false

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("名称", text: $name)
                DatePicker("日期", selection: $date, displayedComponents: .date)
                HStack {
                    Text("金额")
                    Spacer()
                    TextField("金额", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            Section("分类") {
                Picker("分类", selection: $category) {
                    Text("工作").tag("工作")
                    Text("生活").tag("生活")
                    Text("学习").tag("学习")
                }
            }
            Section("其他") {
                Toggle("收藏", isOn: $isFavorite)
            }
        }
        .navigationTitle("详情")
        .navigationBarTitleDisplayMode(.inline)
        .contentMargins(.bottom, 96, for: .scrollContent)
    }
}