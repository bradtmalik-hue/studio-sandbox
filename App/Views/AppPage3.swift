import SwiftUI

struct AppPage3View: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("annualGoal") private var annualGoal: Int = 12

    @State private var goalInput: Int = 12
    @State private var showSaveAlert = false
    @State private var showResetAlert = false

    private var completedCount: Int {
        store.books.filter { $0.totalPages > 0 && $0.currentPage >= $0.totalPages }.count
    }

    private var readingCount: Int {
        store.books.count - completedCount
    }

    var progress: Double {
        let goal = max(annualGoal, 1)
        return min(Double(completedCount) / Double(goal), 1.0)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("年度目标", systemImage: "target")
                                .font(.headline)
                            Spacer()
                            Text("\(goalInput) 本")
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                        }
                        Stepper(value: $goalInput, in: 1...365, step: 1) {
                            Text("每年读几本")
                        }
                        TextField("目标", value: $goalInput, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 120)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("目标")
                } footer: {
                    Text("设定每年想读完的书籍数量，可在首页查看进度。")
                }

                Section {
                    AppPage3StatRow(label: "已读完", value: "\(completedCount) 本", icon: "checkmark.circle.fill", color: .green)
                    AppPage3StatRow(label: "正在读", value: "\(readingCount) 本", icon: "book.fill", color: .blue)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("年度进度")
                            Spacer()
                            Text("\(Int(progress * 100))%")
                        }
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("当前进度")
                }

                Section {
                    Button {
                        saveGoal()
                    } label: {
                        HStack {
                            Spacer()
                            Label("保存目标", systemImage: "checkmark.circle")
                            Spacer()
                        }
                    }
                    .disabled(goalInput < 1 || goalInput > 365)

                    Button(role: .destructive) {
                        goalInput = 12
                        showResetAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("恢复默认", systemImage: "arrow.counterclockwise")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .alert("已保存", isPresented: $showSaveAlert) {
                Button("好", role: .cancel) { }
            } message: {
                Text("年度目标已更新为 \(goalInput) 本")
            }
            .alert("已重置", isPresented: $showResetAlert) {
                Button("好", role: .cancel) { }
            } message: {
                Text("年度目标已恢复为默认的 12 本，点击保存后生效")
            }
            .onAppear {
                goalInput = annualGoal > 0 ? annualGoal : 12
            }
        }
    }

    private func saveGoal() {
        annualGoal = goalInput
        showSaveAlert = true
    }
}

struct AppPage3StatRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Label {
                Text(label)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(color)
            }
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AppPage3View()
        .environmentObject(AppStore())
}