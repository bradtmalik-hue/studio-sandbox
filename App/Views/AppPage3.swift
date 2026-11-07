import SwiftUI
import Foundation

private struct AppPage3SummaryCard: View {
    let goal: Int
    let readCount: Int
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(readCount)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text("/ \(goal) 本")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "books.vertical.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.accentColor)
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)

            HStack {
                Text("已完成 \(Int(progress * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(readCount >= goal ? "已达成年度目标" : "继续加油")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

struct AppPage3View: View {
    @EnvironmentObject var store: AppStore
    @State private var showingResetAlert = false

    private var readBookCount: Int {
        Set(store.quotes.map { $0.bookTitle }).count
    }

    var goal: Binding<Int> {
        Binding(
            get: { store.settings.yearlyReadingGoal },
            set: { newValue in
                store.objectWillChange.send()
                store.settings.yearlyReadingGoal = max(1, newValue)
                store.settings.updatedAt = Date()
                persistSettings()
            }
        )
    }

    private var progress: Double {
        let goalValue = max(1, goal.wrappedValue)
        return min(Double(readBookCount) / Double(goalValue), 1.0)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage3SummaryCard(
                        goal: goal.wrappedValue,
                        readCount: readBookCount,
                        progress: progress
                    )
                } header: {
                    Text("年度阅读")
                }

                Section {
                    HStack {
                        Stepper(value: goal, in: 1...365, step: 1) {
                            Label("每年读书目标", systemImage: "target")
                        }
                        Spacer()
                        Text("\(goal.wrappedValue) 本")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("已读本数", systemImage: "books.vertical")
                        Spacer()
                        Text("\(readBookCount) 本")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("目标进度", systemImage: "chart.pie")
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("目标与进度")
                } footer: {
                    Text("已读本数按书摘中出现的不同书名统计。")
                }

                if store.quotes.isEmpty {
                    Section {
                        AppPage3EmptyView()
                    }
                } else {
                    Section {
                        Button {
                            showingResetAlert = true
                        } label: {
                            Label("重置目标", systemImage: "arrow.counterclockwise")
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("设置")
            .contentMargins(.bottom, 96, for: .scrollContent)
            .alert("重置目标？", isPresented: $showingResetAlert) {
                Button("取消", role: .cancel) { }
                Button("重置") {
                    goal.wrappedValue = 12
                    persistSettings()
                }
            } message: {
                Text("将年度目标恢复为 12 本。")
            }
        }
    }

    private var settingsFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("settings.json")
    }

    private func persistSettings() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(store.settings)
            try data.write(to: settingsFileURL)
        } catch {
        }
    }
}