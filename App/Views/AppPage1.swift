import SwiftUI
import Foundation

struct AppPage1View: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage1RingCard(
                        progress: todayProgress,
                        totalMl: todayTotal,
                        goalMl: store.dailyGoalMl,
                        recordCount: todayRecords.count,
                        latestTime: latestTimeText
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                Section {
                    HStack(spacing: 12) {
                        Button {
                            addWater(250)
                        } label: {
                            Label("喝一杯 250 ml", systemImage: "drop.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)

                        Button {
                            addWater(500)
                        } label: {
                            Label("喝一杯 500 ml", systemImage: "waterbottle.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }

                Section("今天记录") {
                    if todayRecords.isEmpty {
                        ContentUnavailableView {
                            Label("还没有喝水记录", systemImage: "drop")
                        } description: {
                            Text("点击上方按钮，记录第一杯水")
                        } actions: {
                            Button("添加 250 ml") {
                                addWater(250)
                            }
                        }
                    } else {
                        ForEach(todayRecords) { record in
                            AppPage1RecordRow(record: record)
                        }
                        .onDelete(perform: deleteRecords)
                    }
                }
            }
            .contentMargins(.bottom, 96, for: .scrollContent)
            .navigationTitle("今天")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addWater(250)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private var todayRecords: [AppWaterRecord] {
        let start = Calendar.current.startOfDay(for: Date())
        return store.records
            .filter { $0.date >= start }
            .sorted { $0.date < $1.date }
    }

    private var todayTotal: Int {
        todayRecords.reduce(0) { $0 + $1.amountMl }
    }

    private var todayProgress: Double {
        guard store.dailyGoalMl > 0 else { return 0 }
        return min(Double(todayTotal) / Double(store.dailyGoalMl), 1.0)
    }

    private var latestTimeText: String {
        guard let latest = todayRecords.max(by: { $0.date < $1.date }) else { return "—" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: latest.date)
    }

    private func addWater(_ ml: Int) {
        let record = AppWaterRecord(id: UUID(), amountMl: ml, date: Date())
        store.records.append(record)
        store.save()
    }

    private func deleteRecords(at offsets: IndexSet) {
        let sorted = todayRecords
        let toDelete = offsets.map { sorted[$0] }
        store.records.removeAll { record in
            toDelete.contains { $0.id == record.id }
        }
        store.save()
    }
}

struct AppPage1RingCard: View {
    let progress: Double
    let totalMl: Int
    let goalMl: Int
    let recordCount: Int
    let latestTime: String

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 18)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.cyan, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 4) {
                    Text("\(totalMl)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                    Text("ml / \(goalMl) ml")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 180, height: 180)

            HStack {
                Label("\(recordCount) 条", systemImage: "list.bullet")
                Spacer()
                Label("最近 \(latestTime)", systemImage: "clock")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct AppPage1RecordRow: View {
    let record: AppWaterRecord

    var body: some View {
        HStack {
            Image(systemName: "drop.fill")
                .foregroundStyle(.cyan)
                .frame(width: 28)
            VStack(alignment: .leading) {
                Text("喝水")
                Text(timeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(record.amountMl) ml")
                .font(.headline)
        }
        .padding(.vertical, 4)
    }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: record.date)
    }
}