import SwiftUI
import Foundation

private enum AppPage1Format {
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()
}

struct AppPage1Row: View {
    let pet: AppPet

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.18))
                Text(String(pet.name.prefix(1)))
                    .font(.headline)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(pet.name)
                        .font(.headline)
                    Spacer()
                    Text("\(pet.species) · \(pet.breed)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Label(String(format: "%.1f kg", pet.weight), systemImage: "scalemass")
                    Label(AppPage1Format.fullDate.string(from: pet.birthday), systemImage: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct AppPage1Empty: View {
    let searchActive: Bool
    let onAdd: () -> Void

    var body: some View {
        if searchActive {
            ContentUnavailableView(
                "没有匹配的宠物",
                systemImage: "magnifyingglass",
                description: Text("换个名字或筛选条件试试")
            )
        } else {
            ContentUnavailableView {
                Label("还没有宠物档案", systemImage: "pawprint.fill")
            } description: {
                Text("添加第一条宠物档案，开始记录疫苗")
            } actions: {
                Button("添加宠物") {
                    onAdd()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct AppPage1EditView: View {
    let pet: AppPet?

    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var species: String
    @State private var breed: String
    @State private var birthday: Date
    @State private var weightText: String
    @State private var color: String
    @State private var notes: String

    @State private var hasChanges = false
    @State private var showValidationAlert = false
    @State private var showDiscardAlert = false
    @State private var showDeleteConfirm = false

    init(pet: AppPet?) {
        self.pet = pet
        _name = State(initialValue: pet?.name ?? "")
        _species = State(initialValue: pet?.species ?? "狗")
        _breed = State(initialValue: pet?.breed ?? "")
        _birthday = State(initialValue: pet?.birthday ?? Date())
        _weightText = State(initialValue: pet.map { String(format: "%.1f", $0.weight) } ?? "")
        _color = State(initialValue: pet?.color ?? "")
        _notes = State(initialValue: pet?.notes ?? "")
    }

    private var canSave: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return false }
        guard let weight = Double(weightText), weight > 0 else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("宠物名字", text: $name)
                    TextField("种类（如：狗、猫）", text: $species)
                    TextField("品种（如：金毛、布偶）", text: $breed)
                }

                Section("身体信息") {
                    DatePicker("出生日期", selection: $birthday, displayedComponents: .date)
                    TextField("体重（千克）", text: $weightText)
                        .keyboardType(.decimalPad)
                    TextField("毛色", text: $color)
                }

                Section("备注") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }

                if pet != nil {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("删除这条档案", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(pet == nil ? "添加宠物" : "宠物详情")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if hasChanges {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .alert("保存不了", isPresented: $showValidationAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text("请填写名字和有效体重（大于0）")
            }
            .alert("放弃修改？", isPresented: $showDiscardAlert) {
                Button("继续编辑", role: .cancel) {}
                Button("放弃", role: .destructive) { dismiss() }
            } message: {
                Text("你还有未保存的修改")
            }
            .alert("删除宠物档案？", isPresented: $showDeleteConfirm) {
                Button("删除", role: .destructive) { deleteAndDismiss() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("该宠物的疫苗记录和提醒也会一并删除")
            }
            .onChange(of: name) { _ in hasChanges = true }
            .onChange(of: species) { _ in hasChanges = true }
            .onChange(of: breed) { _ in hasChanges = true }
            .onChange(of: birthday) { _ in hasChanges = true }
            .onChange(of: weightText) { _ in hasChanges = true }
            .onChange(of: color) { _ in hasChanges = true }
            .onChange(of: notes) { _ in hasChanges = true }
            .interactiveDismissDisabled(hasChanges)
        }
    }

    func save() {
        guard canSave else {
            showValidationAlert = true
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedSpecies = species.trimmingCharacters(in: .whitespaces)
        let finalSpecies = trimmedSpecies.isEmpty ? "其他" : trimmedSpecies
        let weight = Double(weightText) ?? 0

        let newPet = AppPet(id: pet?.id ?? UUID(), name: trimmedName, species: finalSpecies, breed: breed, birthday: birthday, weight: weight, color: color, notes: notes, createdAt: pet?.createdAt ?? Date(), map: "")

        if let existingPet = pet,
           let index = store.pets.firstIndex(where: { $0.id == existingPet.id }) {
            store.pets[index] = newPet
        } else {
            store.pets.append(newPet)
        }

        store.save()
        dismiss()
    }

    private func deleteAndDismiss() {
        guard let pet = pet else { return }

        store.pets.removeAll { $0.id == pet.id }
        store.vaccineRecords.removeAll { $0.petID == pet.id }
        store.save()
        dismiss()
    }
}

struct AppPage1View: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""
    @State private var filterSpecies = "全部"
    @State private var showingAdd = false

    private var filteredPets: [AppPet] {
        store.pets
            .filter { pet in
                let matchesSearch = searchText.isEmpty
                    || pet.name.localizedCaseInsensitiveContains(searchText)
                    || pet.species.localizedCaseInsensitiveContains(searchText)
                    || pet.breed.localizedCaseInsensitiveContains(searchText)

                let matchesFilter: Bool
                switch filterSpecies {
                case "狗":
                    matchesFilter = pet.species.contains("狗")
                case "猫":
                    matchesFilter = pet.species.contains("猫")
                case "其他":
                    matchesFilter = !pet.species.contains("狗") && !pet.species.contains("猫")
                default:
                    matchesFilter = true
                }

                return matchesSearch && matchesFilter
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var totalWeight: Double {
        store.pets.reduce(0) { $0 + $1.weight }
    }

    private var latestAddedText: String {
        guard let latest = store.pets.max(by: { $0.createdAt < $1.createdAt }) else {
            return "暂无"
        }
        return AppPage1Format.shortDate.string(from: latest.createdAt)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                summaryCard
                searchAndFilter

                List {
                    ForEach(filteredPets) { pet in
                        NavigationLink {
                            AppPage1EditView(pet: pet)
                        } label: {
                            AppPage1Row(pet: pet)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                delete(pet)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .contentMargins(.bottom, 96, for: .scrollContent)
                .overlay {
                    if filteredPets.isEmpty {
                        AppPage1Empty(
                            searchActive: !searchText.isEmpty || filterSpecies != "全部",
                            onAdd: { showingAdd = true }
                        )
                    }
                }
            }
            .navigationTitle("宠物档案")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("添加宠物", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AppPage1EditView(pet: nil)
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("宠物档案", systemImage: "pawprint.fill")
                    .font(.headline)
                Spacer()
                Text("记疫苗更安心")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading) {
                    Text("\(store.pets.count)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("只宠物")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text(String(format: "%.1f", totalWeight))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("总体重(kg)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text(latestAddedText)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text("最近添加")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var searchAndFilter: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索名字、品种或种类", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color.gray.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Picker("种类筛选", selection: $filterSpecies) {
                ForEach(["全部", "狗", "猫", "其他"], id: \.self) { option in
                    Text(option)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    func delete(_ pet: AppPet) {
        store.pets.removeAll { $0.id == pet.id }
        store.vaccineRecords.removeAll { $0.petID == pet.id }
        store.save()
    }
}