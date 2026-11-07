import SwiftUI

struct AppPage3View: View {
    private let progressRows: [(title: String, value: String)] = [
        ("Total Workouts", "12"),
        ("Total Minutes", "540"),
        ("Total Calories", "4200"),
        ("Current Streak", "5 days")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppPage3GoalCard()
                }

                Section("Progress") {
                    ForEach(progressRows, id: \.title) { row in
                        AppPage3ProgressRow(title: row.title, value: row.value)
                    }
                }
            }
            .navigationTitle("Progress")
        }
    }
}

struct AppPage3ProgressRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

struct AppPage3GoalCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Goal")
                .font(.headline)
            Text("Stay consistent and hit your movement target.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}