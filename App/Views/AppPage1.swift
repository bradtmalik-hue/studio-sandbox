import SwiftUI
import Foundation

struct AppPage1View: View {
    @EnvironmentObject var store: AppStore
    @State private var showAddMeal = false
    @State private var editingMeal: AppMeal? = nil
    @State private var filterType: AppMealType? = nil
    
    private var todayMeals: [AppMeal] {
        store.meals
            .filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date > $1.date }
    }
    
    private var uniqueMealTypes: [AppMealType] {
        Array(Set(todayMeals.map { $0.mealType }))
            .sorted { $0.rawValue < $1.rawValue }
    }
    
    var filteredMeals: [AppMeal] {
        guard let filterType = filterType else { return todayMeals }
        return todayMeals.filter { $0.mealType == filterType }
    }
    
    var totalCalories: Double {
        filteredMeals.reduce(0) { $0 + $1.calories }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage1SummaryCard(
                        mealCount: filteredMeals.count,
                        totalCalories: totalCalories,
                        latestDate: filteredMeals.first?.date
                    )
                }
                
                if !todayMeals.isEmpty {
                    Section {
                        Picker("筛选", selection: $filterType) {
                            Text("全部").tag(nil as AppMealType?)
                            ForEach(uniqueMealTypes, id: \.self) { type in
                                Text(appPage1MealTypeName(type)).tag(Optional(type))
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                if filteredMeals.isEmpty {
                    Section {
                        AppPage1EmptyView(
                            title: todayMeals.isEmpty ? "今天还没有喂食记录" : "没有符合筛选的记录",
                            message: todayMeals.isEmpty ? "点一下右上角 + 按钮，记录第一顿。" : "换个筛选条件试试。",
                            buttonTitle: todayMeals.isEmpty ? "添加第一条" : "清除筛选",
                            action: {
                                if todayMeals.isEmpty {
                                    showAddMeal = true
                                } else {
                                    filterType = nil
                                }
                            }
                        )
                    }
                } else {
                    Section {
                        ForEach(filteredMeals) { meal in
                            Button {
                                editingMeal = meal
                            } label: {
                                AppPage1Row(meal: meal)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteMeals)
                    }
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("今天")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddMeal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("添加喂食记录")
                }
            }
            .sheet(isPresented: $showAddMeal) {
                AppPage1EditView(meal: nil)
            }
            .sheet(item: $editingMeal) { meal in
                AppPage1EditView(meal: meal)
            }
        }
    }
    
    private func deleteMeals(at offsets: IndexSet) {
        let mealsToDelete = offsets.map { filteredMeals[$0] }
        for meal in mealsToDelete {
            store.meals.removeAll { $0.id == meal.id }
        }
        store.save()
    }
}

struct AppPage1SummaryCard: View {
    let mealCount: Int
    let totalCalories: Double
    let latestDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("今日概览", systemImage: "chart.bar.fill")
                    .font(.headline)
                Spacer()
            }
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("\(mealCount)")
                        .font(.system(size: 34, weight: .bold))
                    Text("餐")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading) {
                    Text(String(format: "%.0f", totalCalories))
                        .font(.system(size: 34, weight: .bold))
                    Text("千卡")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading) {
                    Text(latestDate.map { appPage1TimeString($0) } ?? "--:--")
                        .font(.system(size: 20, weight: .semibold))
                    Text("最近一次")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AppPage1Row: View {
    let meal: AppMeal
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: appPage1MealTypeIcon(meal.mealType))
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.12), in: Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(meal.foodName)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(appPage1MealTypeName(meal.mealType))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1), in: Capsule())
                }
                HStack(spacing: 12) {
                    Label(appPage1TimeString(meal.date), systemImage: "clock")
                    Label(String(format: "%.0f 千卡", meal.calories), systemImage: "flame")
                    if meal.amount != 0 {
                        Label(String(format: "%.1f 份", meal.amount), systemImage: "scalemass")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if !meal.note.isEmpty {
                    Text(meal.note)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct AppPage1EmptyView: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "fork.knife")
        } description: {
            Text(message)
        } actions: {
            Button(buttonTitle, action: action)
                .buttonStyle(.borderedProminent)
        }
    }
}

struct AppPage1EditView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    
    let meal: AppMeal?
    
    @State private var foodName: String
    @State private var amount: Double
    @State private var calories: Double
    @State private var mealType: AppMealType
    @State private var note: String
    @State private var date: Date
    @State private var autoReturn: Bool = true
    @State private var showingCancelAlert = false
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    @State private var isDirty: Bool = false
    
    init(meal: AppMeal?) {
        self.meal = meal
        _foodName = State(initialValue: meal?.foodName ?? "")
        _amount = State(initialValue: meal?.amount ?? 100)
        _calories = State(initialValue: meal?.calories ?? 200)
        _mealType = State(initialValue: meal?.mealType ?? .breakfast)
        _note = State(initialValue: meal?.note ?? "")
        _date = State(initialValue: meal?.date ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("食物") {
                    TextField("食物名称", text: $foodName)
                        .textInputAutocapitalization(.never)
                }
                
                Section("份量与营养") {
                    HStack {
                        Text("份量")
                        Spacer()
                        TextField("0.0", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    HStack {
                        Text("热量（千卡）")
                        Spacer()
                        TextField("0", value: $calories, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                
                Section("餐类型") {
                    Picker("餐类型", selection: $mealType) {
                        ForEach([AppMealType.breakfast, .lunch, .dinner, .snack], id: \.self) { type in
                            Text(appPage1MealTypeName(type)).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("时间") {
                    DatePicker("喂食时间", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("备注") {
                    TextField("备注（可选）", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section {
                    Toggle("保存后返回今天页", isOn: $autoReturn)
                }
                
                Section {
                    Button("保存记录") {
                        saveMeal()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(foodName.trimmingCharacters(in: .whitespaces).isEmpty || calories < 0 || amount <= 0)
                }
            }
            .navigationTitle(meal == nil ? "添加喂食" : "编辑喂食")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if isDirty {
                            showingCancelAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .onChange(of: foodName) { _ in markDirty() }
            .onChange(of: amount) { _ in markDirty() }
            .onChange(of: calories) { _ in markDirty() }
            .onChange(of: mealType) { _ in markDirty() }
            .onChange(of: note) { _ in markDirty() }
            .onChange(of: date) { _ in markDirty() }
            .alert("放弃修改？", isPresented: $showingCancelAlert) {
                Button("继续编辑", role: .cancel) { }
                Button("放弃", role: .destructive) { dismiss() }
            } message: {
                Text("你还有未保存的修改。")
            }
            .alert("无法保存", isPresented: $showingValidationAlert) {
                Button("好", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .interactiveDismissDisabled(isDirty)
        }
    }
    
    private func markDirty() {
        if !isDirty { isDirty = true }
    }
    
    private func saveMeal() {
        let trimmedName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = "请填写食物名称。"
            showingValidationAlert = true
            return
        }
        guard amount > 0 else {
            validationMessage = "份量必须大于 0。"
            showingValidationAlert = true
            return
        }
        guard calories >= 0 else {
            validationMessage = "热量不能为负数。"
            showingValidationAlert = true
            return
        }
        
        if let existing = meal, let index = store.meals.firstIndex(where: { $0.id == existing.id }) {
            store.meals[index].foodName = trimmedName
            store.meals[index].amount = amount
            store.meals[index].calories = calories
            store.meals[index].mealType = mealType
            store.meals[index].note = note
            store.meals[index].date = date
        } else {
            let newMeal = AppMeal(id: UUID(), date: Date(), foodName: trimmedName, amount: amount, calories: calories, mealType: mealType, note: note)
            store.meals.append(newMeal)
        }
        store.save()
        dismiss()
    }
}

private func appPage1MealTypeName(_ type: AppMealType) -> String {
    switch type {
    case .breakfast: return "早餐"
    case .lunch: return "午餐"
    case .dinner: return "晚餐"
    case .snack: return "零食"
    default: return type.rawValue
    }
}

private func appPage1MealTypeIcon(_ type: AppMealType) -> String {
    switch type {
    case .breakfast: return "sunrise.fill"
    case .lunch: return "sun.max.fill"
    case .dinner: return "moon.stars.fill"
    case .snack: return "leaf.fill"
    default: return "fork.knife"
    }
}

private func appPage1TimeString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M月d日 HH:mm"
    return formatter.string(from: date)
}