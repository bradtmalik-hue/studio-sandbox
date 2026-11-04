import SwiftUI

struct SandboxProbeInsightView: View {
    @EnvironmentObject private var store: HomeStore

    private var thisWeek: Int {
        let cal = Calendar.current
        return store.items.filter {
            (cal.dateComponents([.day], from: $0.createdAt, to: Date()).day ?? 99) < 7
        }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("一共记了").font(.headline)
                    Text("\(store.count) 条")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    HStack(spacing: 24) {
                        VStack(alignment: .leading) {
                            Text("最近 7 天").font(.caption).foregroundStyle(.secondary)
                            Text("\(thisWeek)").font(.title2.monospacedDigit())
                        }
                        VStack(alignment: .leading) {
                            Text("最早一条").font(.caption).foregroundStyle(.secondary)
                            Text(store.items.last.map {
                                $0.createdAt.formatted(date: .abbreviated, time: .omitted)
                            } ?? "—").font(.subheadline)
                        }
                    }
                    Divider()
                    Text("最近 5 条").font(.headline)
                    ForEach(store.items.prefix(5)) { item in
                        HStack {
                            Text(item.createdAt, format: .dateTime.month().day().hour().minute())
                                .font(.caption).foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
            .navigationTitle("Stats")
        }
    }
}
