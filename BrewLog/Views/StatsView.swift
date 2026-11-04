import SwiftUI
import Charts

struct StatsView: View {
    private struct StatEntry: Identifiable {
        let id = UUID()
        let label: String
        let value: Int
    }

    private let entries: [StatEntry] = [
        StatEntry(label: "Mon", value: 12),
        StatEntry(label: "Tue", value: 18),
        StatEntry(label: "Wed", value: 15),
        StatEntry(label: "Thu", value: 22),
        StatEntry(label: "Fri", value: 17),
        StatEntry(label: "Sat", value: 25),
        StatEntry(label: "Sun", value: 19)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summarySection
                    chartSection
                    entriesSection
                }
                .padding()
            }
            .navigationTitle("Statistics")
        }
    }

    private var totalValue: Int {
        entries.reduce(0) { $0 + $1.value }
    }

    private var averageValue: Int {
        entries.isEmpty ? 0 : totalValue / entries.count
    }

    private var bestValue: Int {
        entries.map(\.value).max() ?? 0
    }

    private var summarySection: some View {
        HStack(spacing: 12) {
            summaryCard(title: "Total", value: totalValue)
            summaryCard(title: "Average", value: averageValue)
            summaryCard(title: "Best", value: bestValue)
        }
    }

    private func summaryCard(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value, format: .number)
                .font(.title3.bold())
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var chartSection: some View {
        Chart(entries) { entry in
            BarMark(
                x: .value("Day", entry.label),
                y: .value("Value", entry.value)
            )
            .foregroundStyle(Color.blue.gradient)
        }
        .frame(height: 220)
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var entriesSection: some View {
        VStack(spacing: 8) {
            ForEach(entries) { entry in
                HStack {
                    Text(entry.label)
                        .font(.body)
                    Spacer()
                    Text(entry.value, format: .number)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    StatsView()
}