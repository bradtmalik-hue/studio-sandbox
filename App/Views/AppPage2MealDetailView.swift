import SwiftUI

struct AppPage2MealDetailView: View {
    @State private var mealName: String = "示例餐食"
    @State private var mealDate: Date = Date()
    @State private var calories: Double = 350
    @State private var category: String = "早餐"
    @State private var isFavorite: Bool = false
    @State private var notes: String = "这是一条示例记录"

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("名称", text: $mealName)
                DatePicker("日期", selection: $mealDate)
                Picker("分类", selection: $category) {
                    Text("早餐").tag("早餐")
                    Text("午餐").tag("午餐")
                    Text("晚餐").tag("晚餐")
                    Text("加餐").tag("加餐")
                }
                Toggle("收藏", isOn: $isFavorite)
                Stepper("卡路里: \(Int(calories))", value: $calories, in: 0...2000, step: 10)
            }
            Section("备注") {
                TextEditor(text: $notes)
                    .frame(height: 100)
            }
        }
        .navigationTitle("餐食详情")
    }
}