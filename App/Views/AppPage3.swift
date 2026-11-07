import SwiftUI

struct AppPage3View: View {
    @EnvironmentObject private var store: AppStore
    @State private var goalText: String = ""
    @State private var isGoalFocused = false
    @State private var showSavedAlert = false
    @State private var showResetConfirmation = false

    private var isValidGoal: Bool {
        guard let value = Int(goalText), value >= 0, value <= 999 else { return false }
        return true
    }

    private var activeBooksCount: Int {
        store.books.filter { $0.currentPage < $0.totalPages }.count
    }

    private var finishedBooksCount: Int {
        store.books.filter { $0.currentPage >= $0.totalPages }.count
    }

    private var totalCurrentPages: Int {
        store.books.reduce(0) { $0 + $1.currentPage }
    }

    var totalPages: Int {
        store.books.reduce(0) { $0 + $1.totalPages }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("目标") {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("年度阅读目标", systemImage: "target")
                            .font(.headline)
                        Text("设定每年想读完的图书数量，首页将用这个目标来显示年度进度。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack {
                            TextField("例如 24", text: $goalText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                                .focused($isGoalFocused)
                                .onChange(of: goalText) { _, newValue in
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered != newValue {
                                        goalText = String(filtered.prefix(3))
                                    }
                                    if let value = Int(filtered), value > 999 {
                                        goalText = String(filtered.prefix(3))
                                    }
                                }

                            Stepper("本", value: Binding(
                                get: { Int(goalText) ?? 0 },
                                set: { newValue in
                                    let clamped = max(0, min(999, newValue))
                                    goalText = String(clamped)
                                }
                            ), in: 0...999)
                            .labelsHidden()
                        }

                        HStack {
                            ForEach([12, 24, 36, 52], id: \.self) { value in
                                Button("\(value)本") {
                                    goalText = String(value)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }

                        Text("当前目标：\(store.yearlyGoal) 本/年")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section("今年阅读概览") {
                    if store.books.isEmpty {
                        AppPage3EmptyReadingState()
                    } else {
                        AppPage3StatRow(
                            title: "正在读",
                            value: "\(activeBooksCount) 本",
                            systemImage: "book.fill",
                            color: .blue
                        )
                        AppPage3StatRow(
                            title: "读完",
                            value: "\(finishedBooksCount) 本",
                            systemImage: "checkmark.circle.fill",
                            color: .green
                        )
                        AppPage3StatRow(
                            title: "总页数进度",
                            value: "\(totalCurrentPages) / \(totalPages) 页",
                            systemImage: "text.book.closed.fill",
                            color: .orange
                        )
                        AppPage3StatRow(
                            title: "摘录",
                            value: "\(store.excerpts.count) 条",
                            systemImage: "quote.bubble.fill",
                            color: .purple
                        )

                        if totalPages > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                ProgressView(value: Double(totalCurrentPages), total: Double(totalPages))
                                Text("已读 \(totalCurrentPages) / \(totalPages) 页")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section("保存与重置") {
                    Button {
                        saveGoal()
                    } label: {
                        Label("保存目标", systemImage: "square.and.arrow.down.fill")
                    }
                    .disabled(!isValidGoal)

                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("恢复默认目标", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("设置")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        isGoalFocused = false
                    }
                }
            }
            .onAppear {
                goalText = String(store.yearlyGoal)
            }
            .alert("已保存", isPresented: $showSavedAlert) {
                Button("好", role: .cancel) {}
            } message: {
                Text("年度目标已更新为 \(store.yearlyGoal) 本。")
            }
            .confirmationDialog("恢复默认目标？", isPresented: $showResetConfirmation, titleVisibility: .visible) {
                Button("恢复为 24 本", role: .destructive) {
                    goalText = "24"
                    saveGoal()
                }
                Button("取消", role: .cancel) {}
            }
        }
    }

    private func saveGoal() {
        guard let value = Int(goalText), value >= 0, value <= 999 else { return }
        store.yearlyGoal = value
        store.save()
        isGoalFocused = false
        showSavedAlert = true
    }
}

private struct AppPage3StatRow: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
                .foregroundStyle(color)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

private struct AppPage3EmptyReadingState: View {
    var body: some View {
        ContentUnavailableView {
            Label("还没有在读的书", systemImage: "books.vertical")
        } description: {
            Text("先到「正在读」页添加一本书，这里会显示你的阅读概览。")
        }
    }
}