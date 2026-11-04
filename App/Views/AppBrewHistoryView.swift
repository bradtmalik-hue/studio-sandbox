import SwiftUI
import Foundation

struct AppBrewHistoryView: View {
    @EnvironmentObject var brewStore: AppBrewStore
    @EnvironmentObject var beanStore: AppBeanStore

    @State private var showBestOnly = false

    private var allRecords: [AppBrewRecord] {
        brewStore.records.sorted { $0.date > $1.date }
    }

    private var filteredRecords: [AppBrewRecord] {
        if showBestOnly {
            return allRecords.filter(\.isBest)
        }
        return allRecords
    }

    private var bestCount: Int {
        allRecords.filter(\.isBest).count
    }

    var body: some View {
        NavigationStack {
            Group {
                if allRecords.isEmpty {
                    ContentUnavailableView(
                        "还没有冲煮记录",
                        systemImage: "cup.and.saucer",
                        description: Text("去“冲煮记录”页添加第一杯，豆子还剩多少一冲就知道。")
                    )
                } else if filteredRecords.isEmpty {
                    ContentUnavailableView(
                        "没有最佳一杯",
                        systemImage: "star",
                        description: Text("标记你最喜欢的记录，快速找到最好喝的那一杯。")
                    )
                } else {
                    List {
                        Section {
                            ForEach(filteredRecords) { record in
                                AppBrewHistoryRow(
                                    record: record,
                                    beanName: beanName(for: record.beanID)
                                )
                                .swipeActions {
                                    Button {
                                        withAnimation {
                                            toggleBest(record)
                                        }
                                    } label: {
                                        Label(
                                            record.isBest ? "取消最佳" : "标记最佳",
                                            systemImage: record.isBest ? "star.slash" : "star"
                                        )
                                    }
                                    .tint(record.isBest ? Color.gray : Color.yellow)
                                }
                            }
                        } footer: {
                            if showBestOnly {
                                Text("筛选：仅显示标记为最佳的一杯")
                            } else {
                                Text("共 \(filteredRecords.count) 条记录\(bestCount > 0 ? "，其中 \(bestCount) 条最佳" : "")")
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("参数历史")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            showBestOnly.toggle()
                        }
                    } label: {
                        Image(systemName: showBestOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel(showBestOnly ? "显示全部记录" : "仅显示最佳一杯")
                }
            }
        }
    }

    private func beanName(for id: UUID) -> String {
        beanStore.beans.first(where: { $0.id == id })?.name ?? "未知豆子"
    }

    private func toggleBest(_ record: AppBrewRecord) {
        guard let index = brewStore.records.firstIndex(where: { $0.id == record.id }) else {
            return
        }
        brewStore.records[index].isBest.toggle()
    }
}

private struct AppBrewHistoryRow: View {
    let record: AppBrewRecord
    let beanName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(beanName)
                    .font(.headline)
                Spacer()
                if record.isBest {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.yellow)
                        .accessibilityLabel("已标记最佳一杯")
                }
            }

            HStack {
                Text(record.date, style: .date)
                Text(record.date, style: .time)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .font(.subheadline)

            HStack(spacing: 12) {
                Label(
                    "\(record.coffeeGrams.formatted(.number.precision(.fractionLength(1))))g",
                    systemImage: "circle.fill"
                )
                Label(
                    "\(record.waterGrams.formatted(.number.precision(.fractionLength(1))))g",
                    systemImage: "drop.fill"
                )
                Label(
                    "\(record.temperature.formatted(.number.precision(.fractionLength(1))))°C",
                    systemImage: "thermometer.medium"
                )
                Label(
                    formatDuration(record.duration),
                    systemImage: "timer"
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
}