import SwiftUI

struct AppPage3View: View {
    @EnvironmentObject private var store: AppStore
    @State private var petNameText: String = ""
    @State private var targetText: String = ""
    @State private var showSavedAlert = false

    private let minTarget = 1
    private let maxTarget = 20

    private var trimmedPetName: String {
        petNameText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedTarget: Int? {
        Int(targetText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var isTargetValid: Bool {
        guard let target = parsedTarget, target >= minTarget, target <= maxTarget else {
            return false
        }
        return true
    }

    private var isFormValid: Bool {
        !trimmedPetName.isEmpty && isTargetValid
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    AppPage3SummaryCard(
                        petName: trimmedPetName.isEmpty ? "未填写" : trimmedPetName,
                        dailyTarget: parsedTarget ?? 0
                    )
                }

                Section {
                    TextField("例如：旺财", text: $petNameText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .submitLabel(.done)
                } header: {
                    Text("宠物信息")
                } footer: {
                    if trimmedPetName.isEmpty {
                        Text("请填写宠物名字")
                            .foregroundStyle(Color.red)
                    } else {
                        Text("这个名字会显示在记录里")
                    }
                }

                Section {
                    HStack {
                        Text("每日目标")
                        Spacer()
                        TextField("1-20", text: $targetText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("次")
                    }

                    Stepper(
                        value: Binding(
                            get: { parsedTarget ?? store.dailyTarget },
                            set: { newValue in
                                let clamped = min(max(newValue, minTarget), maxTarget)
                                targetText = String(clamped)
                                store.dailyTarget = clamped
                            }
                        ),
                        in: minTarget...maxTarget
                    ) {
                        Text("目标调整")
                    }
                } header: {
                    Text("每天喂食次数目标")
                } footer: {
                    if !isTargetValid {
                        Text("目标需在 \(minTarget)-\(maxTarget) 次之间")
                            .foregroundStyle(Color.red)
                    } else {
                        Text("可选择或输入 \(minTarget)-\(maxTarget) 之间的数字")
                    }
                }

                Section {
                    Button {
                        store.petName = trimmedPetName
                        store.dailyTarget = parsedTarget ?? store.dailyTarget
                        store.save()
                        showSavedAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("保存设置", systemImage: "checkmark.circle.fill")
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid)
                    .buttonStyle(.borderedProminent)
                    .tint(.brown)

                    Button("恢复默认") {
                        petNameText = "我的宠物"
                        targetText = "3"
                    }
                    .foregroundStyle(Color.secondary)
                }
            }
            .navigationTitle("设置")
            .onAppear {
                if petNameText.isEmpty {
                    petNameText = store.petName
                    targetText = String(store.dailyTarget)
                }
            }
            .alert("设置已保存", isPresented: $showSavedAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text("宠物名字和每日目标已更新。")
            }
        }
    }
}

struct AppPage3SummaryCard: View {
    let petName: String
    let dailyTarget: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("当前设置", systemImage: "pawprint.fill")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)

            Text(petName)
                .font(.title2.bold())

            Text("每日目标：\(dailyTarget) 次")
                .font(.subheadline)
                .foregroundStyle(dailyTarget > 0 ? Color.primary : Color.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AppPage3EmptyView: View {
    var body: some View {
        ContentUnavailableView(
            "还没有宠物设置",
            systemImage: "pawprint.circle",
            description: Text("请先填写宠物名字和目标")
        )
    }
}