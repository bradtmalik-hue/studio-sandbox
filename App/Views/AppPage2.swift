import SwiftUI

private struct AppPage2DayGroup: Identifiable {
    let id: Date
    let records: [AppWaterRecord]
}

struct AppPage2View: View {
    @ObservedObject var store: AppHydrationStore

    private var groups: [AppPage2DayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.records) { record in
            calendar.startOfDay(for: record.date)
        }
        return grouped
            .map { AppPage2DayGroup(id: $0.key, records: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.id > $1.id }
    }

    var body: some View {
        NavigationView {
            List {
                if store.records.isEmpty {
                    Text("No records yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(groups) { group in
                        Section(header: Text(group.id, style: .date)) {
                            ForEach(group.records, id: \.id) { record in
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(record.container.isEmpty ? "Water" : record.container)
                                            .font(.headline)
                                        if !record.note.isEmpty {
                                            Text(record.note)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text("\(record.amount, specifier: "%.0f") ml")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}