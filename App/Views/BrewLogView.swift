import SwiftUI
import Foundation

struct AppBrewLogView: View {
    @State private var beans: [AppCoffeeBean] = []
    @State private var records: [AppBrewRecord] = []
    @State private var showingNewRecord = false

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cup.and.saucer")
                            .font(.largeTitle)
                        Text("还没有冲煮记录")
                            .font(.headline)
                        Text("点击右上角添加第一杯手冲参数")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(records) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(verbatim: beanName(for: record.beanID))
                                    .font(.headline)
                                Text(record.date, style: .date)
                                    .font(.caption)
                                HStack {
                                    Text(verbatim: "粉水比 1:\(String(format: "%.1f", record.ratio))")
                                    Text(verbatim: "水温 \(String(format: "%.0f", record.waterTemp))°C")
                                    Text(verbatim: "时间 \(String(format: "%.0f", record.time))s")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("冲煮记录")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewRecord = true
                    } label: {
                        Label("添加记录", systemImage: "plus")
                    }
                    .disabled(beans.isEmpty)
                }
            }
            .sheet(isPresented: $showingNewRecord) {
                AppNewBrewLogView(beans: beans) { newRecord, usedGrams in
                    var updatedBeans = beans
                    if let idx = updatedBeans.firstIndex(where: { $0.id == newRecord.beanID }) {
                        updatedBeans[idx].remainingGrams = max(0, updatedBeans[idx].remainingGrams - usedGrams)
                    }
                    beans = updatedBeans
                    records.append(newRecord)
                    saveBeans()
                    saveRecords()
                }
            }
            .onAppear {
                loadBeans()
                loadRecords()
            }
        }
    }

    private func beanName(for id: UUID) -> String {
        beans.first(where: { $0.id == id })?.name ?? "未知豆子"
    }

    private func loadBeans() {
        let url = Self.beansURL
        guard let data = try? Data(contentsOf: url) else { return }
        beans = (try? JSONDecoder().decode([AppCoffeeBean].self, from: data)) ?? []
    }

    private func loadRecords() {
        let url = Self.recordsURL
        guard let data = try? Data(contentsOf: url) else { return }
        records = (try? JSONDecoder().decode([AppBrewRecord].self, from: data)) ?? []
    }

    private func saveBeans() {
        do {
            let data = try JSONEncoder().encode(beans)
            try data.write(to: Self.beansURL)
        } catch {}
    }

    private func saveRecords() {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: Self.recordsURL)
        } catch {}
    }

    private static var beansURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("beans.json")
    }

    private static var recordsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("brewRecords.json")
    }
}

private struct AppNewBrewLogView: View {
    let beans: [AppCoffeeBean]
    var onSave: (AppBrewRecord, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedBeanID: UUID?
    @State private var ratio: Double = 15.0
    @State private var waterTemp: Double = 92.0
    @State private var time: Double = 150.0

    var body: some View {
        NavigationStack {
            Form {
                Section("选择豆子") {
                    Picker("豆子", selection: $selectedBeanID) {
                        ForEach(beans) { bean in
                            Text(verbatim: "\(bean.name)（剩余 \(String(format: "%.0f", bean.remainingGrams))g）")
                                .tag(bean.id as UUID?)
                        }
                    }
                }
                Section("冲煮参数") {
                    HStack {
                        Text("粉水比")
                        Spacer()
                        TextField("1:15", value: $ratio, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("水温 (°C)")
                        Spacer()
                        TextField("92", value: $waterTemp, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("时间 (秒)")
                        Spacer()
                        TextField("150", value: $time, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("新建记录")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let beanID = selectedBeanID,
                              let bean = beans.first(where: { $0.id == beanID }) else { return }
                        let record = AppBrewRecord(
                            id: UUID(),
                            beanID: beanID,
                            ratio: ratio,
                            waterTemp: waterTemp,
                            time: time,
                            date: Date()
                        )
                        onSave(record, bean.defaultCupGrams)
                        dismiss()
                    }
                    .disabled(selectedBeanID == nil)
                }
            }
            .onAppear {
                if selectedBeanID == nil {
                    selectedBeanID = beans.first?.id
                }
            }
        }
    }
}