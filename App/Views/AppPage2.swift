import SwiftUI

enum AppPage2Filter: String, CaseIterable, Identifiable {
    case all
    case hit
    case id
    case miss

    var id: String { rawValue }
}

struct AppPage2DayGroup: View {
    let day: String
    let records: [AppRecord]
    let id: String
    let total: Int

    var body: some View {
        VStack(alignment: .leading) {
            Text(day)
                .font(.headline)
            Text("\(records.count) 条记录")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(Array(records.prefix(3).enumerated()), id: \.offset) { _, record in
                Text("\(record)")
            }
        }
        .padding(.vertical, 4)
    }
}

struct AppPage2SummaryCard: View {
    let records: [AppRecord]
    let total: Int

    var body: some View {
        HStack {
            Text("总计")
            Spacer()
            Text("\(total)")
                .fontWeight(.semibold)
        }
        .padding()
        .background(.quaternary.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

struct AppPage2View: View {
    let records: [AppRecord] = []
    @State private var filter: AppPage2Filter = .all

    var body: some View {
        List {
            ForEach(Array(records.enumerated()), id: \.offset) { _, record in
                AppPage2DayGroup(day: "Day", records: [record], id: UUID().uuidString, total: 1)
            }
            AppPage2SummaryCard(records: records, total: records.count)
        }
        .navigationTitle("Page 2")
        .toolbar {
            Picker("Filter", selection: $filter) {
                ForEach(AppPage2Filter.allCases) { filterCase in
                    Text(filterCase.rawValue.capitalized).tag(filterCase)
                }
            }
        }
    }
}
