import SwiftUI
import Combine

struct BrewSessionView: View {
    @ObservedObject var store: BrewLogStore

    @State private var selectedBeanID: UUID?
    @State private var ratioText: String = ""
    @State private var tempText: String = ""
    @State private var seconds: Int = 0
    @State private var flavor: String = ""
    @State private var date: Date = Date()

    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isRunning = false
    @State private var showSavedAlert = false
    @State private var showNoBeanAlert = false

    init(store: BrewLogStore) {
        self.store = store
    }

    private var selectedBean: BrewBean? {
        store.beans.first { $0.id == selectedBeanID }
    }

    private var formattedElapsed: String {
        let totalSeconds = Int(elapsed)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    var body: some View {
        NavigationStack {
            Form {
                if store.beans.isEmpty {
                    Section {
                        Label("暂无豆子，请先到“豆单”页面添加。", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("豆子") {
                        Picker("选择豆子", selection: $selectedBeanID) {
                            ForEach(store.beans) { bean in
                                Text(bean.name).tag(Optional(bean.id))
                            }
                        }
                    }
                }

                Section("冲煮参数") {
                    HStack {
                        Text("粉水比")
                        Spacer()
                        TextField("1:16", text: $ratioText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }
                    HStack {
                        Text("水温 (°C)")
                        Spacer()
                        TextField("92", text: $tempText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }
                }

                Section("萃取时间") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("秒表")
                            Spacer()
                            Text(formattedElapsed)
                                .font(.title2.monospacedDigit())
                                .foregroundStyle(.primary)
                        }

                        HStack {
                            Button(isRunning ? "暂停" : "开始") {
                                toggleTimer()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("重置") {
                                resetTimer()
                            }
                            .buttonStyle(.bordered)
                            .disabled(elapsed == 0 && !isRunning)
                        }

                        HStack {
                            Text("手动输入秒数")
                            Spacer()
                            TextField("秒", value: $seconds, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 100)
                        }
                    }
                }

                Section("风味与日期") {
                    TextField("风味描述（如：柑橘、红茶、焦糖）", text: $flavor)
                    DatePicker("冲煮日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("冲一杯")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveEntry()
                    }
                    .disabled(selectedBean == nil)
                }
            }
            .onAppear {
                if selectedBeanID == nil, let first = store.beans.first {
                    selectedBeanID = first.id
                }
            }
            .onChange(of: store.beans) { oldValue, newValue in
                if selectedBeanID == nil, let first = newValue.first {
                    selectedBeanID = first.id
                } else if let selectedBeanID, !newValue.contains(where: { $0.id == selectedBeanID }) {
                    self.selectedBeanID = newValue.first?.id
                }
            }
            .alert("已保存", isPresented: $showSavedAlert) {
                Button("好", role: .cancel) { }
            } message: {
                Text("这杯冲煮已记录。")
            }
            .alert("无法保存", isPresented: $showNoBeanAlert) {
                Button("好", role: .cancel) { }
            } message: {
                Text("请先选择一款豆子。")
            }
        }
    }

    private func toggleTimer() {
        if isRunning {
            timer?.invalidate()
            timer = nil
            isRunning = false
            seconds = Int(elapsed)
        } else {
            if elapsed == 0 && seconds > 0 {
                elapsed = TimeInterval(seconds)
            }
            isRunning = true
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                elapsed += 0.1
            }
        }
    }

    private func resetTimer() {
        timer?.invalidate()
        timer = nil
        elapsed = 0
        seconds = 0
        isRunning = false
    }

    private func saveEntry() {
        guard let bean = selectedBean else {
            showNoBeanAlert = true
            return
        }

        if isRunning {
            timer?.invalidate()
            timer = nil
            isRunning = false
            seconds = Int(elapsed)
        }

        let ratio = Double(ratioText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let temp = Double(tempText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let finalSeconds = seconds

        let entry = BrewLogEntry(
            bean: bean,
            ratio: ratio,
            temp: temp,
            seconds: finalSeconds,
            flavor: flavor,
            date: date
        )
        store.addEntry(entry)

        ratioText = ""
        tempText = ""
        seconds = 0
        flavor = ""
        date = Date()
        resetTimer()
        showSavedAlert = true
    }
}