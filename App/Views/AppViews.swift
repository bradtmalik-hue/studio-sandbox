import SwiftUI

struct AppLensLibraryView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if store.lenses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.secondary)
                        Text("还没有镜头")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("点击右上角 + 号添加第一支镜头，记录买价与成色。")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(store.lenses) { lens in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(lens.name)
                                        .font(.headline)
                                    Text(lens.price, format: .currency(code: "CNY"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(lens.condition)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(lens.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("镜头库")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("添加镜头")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AppAddLensView()
                    .environmentObject(store)
            }
        }
    }
}

struct AppAddLensView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var price: Double = 0
    @State private var condition = "全新"
    @State private var purchaseDate = Date()

    private let conditions = ["全新", "近新", "良好", "一般", "战斗"]

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && price >= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("镜头信息") {
                    TextField("镜头名称", text: $name)
                    TextField("买价", value: $price, format: .currency(code: "CNY"))
                        .keyboardType(.decimalPad)
                    Picker("成色", selection: $condition) {
                        ForEach(conditions, id: \.self) { conditionOption in
                            Text(conditionOption)
                        }
                    }
                    DatePicker("购买日期", selection: $purchaseDate, displayedComponents: .date)
                }
            }
            .navigationTitle("添加镜头")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let newLens = AppLens(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            price: price,
                            condition: condition,
                            date: purchaseDate
                        )
                        store.add(newLens)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

struct AppInvestmentStatsView: View {
    @EnvironmentObject var store: AppStore

    private var totalInvestment: Double {
        store.lenses.reduce(0) { $0 + $1.price }
    }

    private var averagePrice: Double {
        store.lenses.isEmpty ? 0 : totalInvestment / Double(store.lenses.count)
    }

    private var mostExpensive: AppLens? {
        store.lenses.max(by: { $0.price < $1.price })
    }

    private var leastExpensive: AppLens? {
        store.lenses.min(by: { $0.price < $1.price })
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.lenses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 56))
                            .foregroundColor(.secondary)
                        Text("暂无投入数据")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("添加镜头后，这里会显示你的器材投入统计。")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section("总览") {
                            HStack {
                                Text("镜头数量")
                                Spacer()
                                Text("\(store.lenses.count)")
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("总投入")
                                Spacer()
                                Text(totalInvestment, format: .currency(code: "CNY"))
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("平均买价")
                                Spacer()
                                Text(averagePrice, format: .currency(code: "CNY"))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Section("最值镜头") {
                            if let lens = mostExpensive {
                                HStack {
                                    Text("最贵")
                                    Spacer()
                                    Text(lens.name)
                                        .foregroundColor(.secondary)
                                    Text(lens.price, format: .currency(code: "CNY"))
                                        .foregroundColor(.secondary)
                                }
                            }
                            if let lens = leastExpensive {
                                HStack {
                                    Text("最便宜")
                                    Spacer()
                                    Text(lens.name)
                                        .foregroundColor(.secondary)
                                    Text(lens.price, format: .currency(code: "CNY"))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("投入统计")
        }
    }
}