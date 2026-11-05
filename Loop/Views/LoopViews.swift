import SwiftUI
import Foundation

struct LoopMomentsView: View {
    @EnvironmentObject var store: LoopStore
    @State private var showingAddMoment = false

    var body: some View {
        NavigationStack {
            Group {
                if store.moments.isEmpty {
                    ContentUnavailableView {
                        Label("No Moments Yet", systemImage: "camera.on.rectangle")
                    } description: {
                        Text("Share your first moment with your closest friends.")
                    } actions: {
                        Button("Add Moment") {
                            showingAddMoment = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(store.moments.indices, id: \.self) { index in
                                let moment = store.moments[index]
                                NavigationLink {
                                    LoopMomentDetailView(moment: moment)
                                } label: {
                                    LoopMomentCard(
                                        moment: moment,
                                        imageName: "sample\(index % 4 + 1)"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Moments")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddMoment = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMoment) {
                LoopAddMomentView()
            }
        }
    }
}

struct LoopMomentCard: View {
    let moment: LoopMoment
    let imageName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(imageName)
                .resizable()
                .aspectRatio(4.0 / 3.0, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [.black.opacity(0.45), .clear],
                        startPoint: .bottom,
                        endPoint: .center
                    )
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(moment.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(moment.date, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding()
                }

            HStack {
                Label(
                    "\(moment.value, specifier: "%.0f")",
                    systemImage: "heart.fill"
                )
                Spacer()
                Text("Loop Moment")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.background)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }
}

struct LoopMomentDetailView: View {
    let moment: LoopMoment

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image("sample1")
                    .resizable()
                    .aspectRatio(4.0 / 3.0, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 8) {
                    Text(moment.name)
                        .font(.title2.bold())
                    Text(moment.date, style: .date)
                        .foregroundStyle(.secondary)
                    Label(
                        "\(moment.value, specifier: "%.0f") moments shared",
                        systemImage: "person.2.fill"
                    )
                }

                Divider()

                Text("This moment will resurface for your closest friends over time.")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Moment")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LoopAddMomentView: View {
    @EnvironmentObject var store: LoopStore
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var date = Date()
    @State private var value = 3.0

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Moment") {
                    TextField("Name", text: $name)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Feeling") {
                    VStack(spacing: 8) {
                        Slider(value: $value, in: 1...5, step: 1)
                        Text("\(value, specifier: "%.0f")")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Save Moment") {
                        let newMoment = LoopMoment(
                            name: trimmedName,
                            date: date,
                            value: value
                        )
                        store.add(newMoment)
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
            .navigationTitle("Add Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LoopLoopView: View {
    @EnvironmentObject var store: LoopStore

    private var totalMoments: Int {
        store.moments.count
    }

    private var averageValue: Double {
        guard !store.moments.isEmpty else { return 0 }
        return store.moments.map(\.value).reduce(0, +) / Double(store.moments.count)
    }

    private var momentsThisWeek: Int {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return store.moments.filter { $0.date >= oneWeekAgo }.count
    }

    private var recentMoments: [LoopMoment] {
        Array(store.moments.sorted { $0.date > $1.date }.prefix(3))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if store.moments.isEmpty {
                        ContentUnavailableView {
                            Label("No Loop Activity", systemImage: "chart.bar.xaxis")
                        } description: {
                            Text("Share a moment to see your loop come alive.")
                        }
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 12
                        ) {
                            LoopStatCard(
                                title: "Total Moments",
                                value: "\(totalMoments)",
                                icon: "camera.on.rectangle"
                            )
                            LoopStatCard(
                                title: "Average Feeling",
                                value: String(format: "%.1f", averageValue),
                                icon: "heart.fill"
                            )
                            LoopStatCard(
                                title: "This Week",
                                value: "\(momentsThisWeek)",
                                icon: "calendar"
                            )
                            LoopStatCard(
                                title: "In the Loop",
                                value: "\(totalMoments)",
                                icon: "person.2.fill"
                            )
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recently Shared")
                                .font(.headline)

                            ForEach(recentMoments, id: \.id) { moment in
                                HStack(spacing: 12) {
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(moment.name)
                                            .font(.subheadline.weight(.medium))
                                        Text(moment.date, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Loop")
        }
    }
}

struct LoopStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct LoopProfileView: View {
    @EnvironmentObject var store: LoopStore
    @State private var showingSeedInfo = false

    var body: some View {
        NavigationStack {
            List {
                Section("Private Loop") {
                    Label("Only close friends can see your moments", systemImage: "lock.fill")
                    Label("Moments resurface over time", systemImage: "clock.arrow.circlepath")
                }

                Section("Local Storage") {
                    Label("\(store.moments.count) moments stored offline", systemImage: "internaldrive.fill")
                    Button("Show Demo Data Info") {
                        showingSeedInfo = true
                    }
                }

                Section("About") {
                    Label("Loop Moments", systemImage: "app.badge")
                    Text("Share your moments, keep your loop")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Profile")
            .alert("Demo Data", isPresented: $showingSeedInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Launch with -demoData to seed example moments.")
            }
        }
    }
}