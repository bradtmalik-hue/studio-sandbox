import SwiftUI
import Foundation

struct AppPage2DetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var amount: Double = 0
    @State private var date: Date = Date()
    @State private var category: String = "餐饮"
    @State private var isFavorite: Bool = false
    @State private var showSavedAlert = false
    @State private var hasChanges = false

    private let categories = ["餐饮", "交通", "购物", "娱乐"]

    private var isSaveDisabled: Bool {
        title.trimmingCharacters(in: .whitespaces).isEmpty || amount <= 0
    }

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("名称", text: $title)
                    .onChange(of: title) { _, _ in hasChanges = true }

                HStack {
                    Text("金额")
                    Spacer()
                    TextField("0.00", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: amount) { _, _ in hasChanges = true }
                }
            }

            Section("日期与分类") {
                DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .onChange(of: date) { _, _ in hasChanges = true }

                Picker("分类", selection: $category) {
                    ForEach(categories, id: \.self) { category in
                        Text(category)
                    }
                }
                .onChange(of: category) { _, _ in hasChanges = true }
            }

            Section("偏好") {
                Toggle("收藏", isOn: $isFavorite)
                    .onChange(of: isFavorite) { _, _ in hasChanges = true }
            }

            Section {
                Button("保存") {
                    hasChanges = false
                    showSavedAlert = true
                }
                .disabled(isSaveDisabled)
            }
        }
        .navigationTitle("详情")
        .navigationBarTitleDisplayMode(.inline)
        .alert("已保存", isPresented: $showSavedAlert) {
            Button("好", role: .cancel) {
                dismiss()
            }
        }
        .onAppear {
            if title.isEmpty {
                title = "午餐"
                amount = 35.5
                date = Date()
                category = "餐饮"
                isFavorite = false
            }
        }
    }
}