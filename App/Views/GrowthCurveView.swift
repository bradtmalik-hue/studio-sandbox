import SwiftUI
import Charts
import Foundation

struct GrowthCurveView: View {
    @ObservedObject var store: AppGrowthStore
    @State private var selectedMonth: Date = Date()
    @State private var showingAddRecord = false

    private var monthRecords: [AppGrowthRecord] {
        let calendar = Calendar.current
        return store.records
            .filter { calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
            .sorted { $0.date < $1.date }
    }

    private var validMonthRecords: [AppGrowthRecord] {
        monthRecords.filter { $0.isValid }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AppMonthNavigator(
                    month: selectedMonth,
                    onPreviousMonth: { shiftMonth(by: -1) },
                    onNextMonth: { shiftMonth(by: 1) }
                )

                if validMonthRecords.isEmpty {
                    contentUnavailable
                } else {
                    growthChart
                    recordsList
                }
            }
            .padding()
        }
        .navigationTitle("Growth Curve")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddRecord = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRecord) {
            AppEntryFormView(
                store: store,
                record: nil,
                date: selectedMonth,
                heightText: "",
                weightText: "",
                focusedField: nil
            )
        }
    }

    private var contentUnavailable: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No valid records for this month")
                .font(.headline)
            Text("Tap + to add a height and weight record.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
    }

    private var growthChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Height")
                .font(.headline)

            Chart {
                ForEach(validMonthRecords) { record in
                    LineMark(
                        x: .value("Date", record.date),
                        y: .value("Height (cm)", record.heightCm)
                    )
                    PointMark(
                        x: .value("Date", record.date),
                        y: .value("Height (cm)", record.heightCm)
                    )
                }
            }
            .frame(height: 180)

            Text("Weight")
                .font(.headline)

            Chart {
                ForEach(validMonthRecords) { record in
                    LineMark(
                        x: .value("Date", record.date),
                        y: .value("Weight (kg)", record.weightKg)
                    )
                    PointMark(
                        x: .value("Date", record.date),
                        y: .value("Weight (kg)", record.weightKg)
                    )
                }
            }
            .frame(height: 180)
        }
    }

    private var recordsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Records")
                .font(.headline)

            ForEach(validMonthRecords) { record in
                HStack {
                    Text(record.date, format: .dateTime.month().day().year())
                    Spacer()
                    Text(String(format: "%.1f cm", record.heightCm))
                    Text(String(format: "%.2f kg", record.weightKg))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func shiftMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
}