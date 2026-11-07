import SwiftUI
import Combine

struct AppPage3View: View {
    @EnvironmentObject var store: AppPayload
    @State private var petName: String = ""
    @State private var dailyGoal: Int = 3
    @State private var showSaveAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage3SummaryCard(
                        totalMeals: store.meals.count,
                        dailyGoal: dailyGoal,
                        petName: petName
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section("宠物信息") {
                    HStack {
                        Label("宠物名字", systemImage: "pawprint.fill")
                        Spacer()
                        TextField("请输入宠物名字", text: $petName)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 220)
                    }
                    HStack {
                        Label("每日喂食目标", systemImage: "target")
                        Spacer()
                        Stepper("\(dailyGoal) 次", value: $dailyGoal, in: 1...12)
                    }
                }

                Section {
                    Button {
                        saveSettings()
                    } label: {
                        Label("保存设置", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section {
                    AppPage3InfoRow(icon: "fork.knife", title: "记录每一餐", detail: "今天页面点击添加即可记录")
                    AppPage3InfoRow(icon: "chart.bar.fill", title: "历史回看", detail: "按天分组浏览喂食次数")
                }
            }
            .navigationTitle("设置")
            .contentMargins(.bottom, 96, for: .scrollContent)
            .alert("设置已保存", isPresented: $showSaveAlert) {
                Button("好", role: .cancel) { }
            } message: {
                Text("宠物名字和每日喂食目标已更新。")
            }
            .onAppear {
                petName = store.settings.petName
                dailyGoal = Int(store.settings.dailyMealTarget)
            }
        }
    }

    private func saveSettings() {
        store.settings.petName = petName.trimmingCharacters(in: .whitespacesAndNewlines)
        store.settings.dailyMealTarget = Double(dailyGoal)
        store.save()
        showSaveAlert = true
    }
}

private struct AppPage3SummaryCard: View {
    let totalMeals: Int
    let dailyGoal: Int
    let petName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("喂养概览", systemImage: "pawprint.circle.fill")
                    .font(.headline)
                Spacer()
                Text(petName.isEmpty ? "未命名宠物" : petName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalMeals)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("总记录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(dailyGoal)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("次/天")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

private struct AppPage3InfoRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}