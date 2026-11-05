import SwiftUI
import Foundation
import Combine

struct LoopMomentRow: View {
    let moment: LoopMoment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(moment.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(moment.note)
                    .font(.headline)
                    .lineLimit(2)

                HStack {
                    Text(moment.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if moment.mood > 0 {
                        Label("\(moment.mood)/5", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct LoopEmptyStateView: View {
    @Binding var showingAddSheet: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.on.rectangle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No moments yet")
                .font(.title2.weight(.semibold))
            Text("Share your first moment and keep your loop alive.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button {
                showingAddSheet = true
            } label: {
                Label("Add a Moment", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

struct LoopMomentsView: View {
    @EnvironmentObject var store: LoopStore
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if store.moments.isEmpty {
                    LoopEmptyStateView(moment: $showingAddSheet)
                } else {
                    List {
                        ForEach(store.moments.sorted { $0.date > $1.date }) { moment in
                            NavigationLink(destination: LoopMomentDetailView(moment: moment)) {
                                LoopMomentRow(moment: moment)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Loop")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                LoopAddMomentView()
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        let sorted = store.moments.sorted { $0.date > $1.date }
        for index in offsets {
            let moment = sorted[index]
            store.delete(moment)
        }
    }
}

struct LoopMomentDetailView: View {
    @EnvironmentObject var store: LoopStore
    let moment: LoopMoment

    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(moment.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                VStack(alignment: .leading, spacing: 12) {
                    Text(moment.note)
                        .font(.title3.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Label(moment.date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if moment.mood > 0 {
                            Label("\(moment.mood)/5", systemImage: "star.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Moment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            LoopEditMomentView(moment: moment)
        }
    }
}

struct LoopAddMomentView: View {
    @EnvironmentObject var store: LoopStore
    @Environment(\.dismiss) private var dismiss

    @State private var note = ""
    @State private var imageName = "sample1"
    @State private var date = Date()
    @State private var mood = 3

    private let imageChoices = ["sample1", "sample2", "sample3", "sample4"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Image") {
                    Picker("Image", selection: $imageName) {
                        ForEach(imageChoices, id: \.self) { name in
                            HStack {
                                Image(name)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                Text(name)
                            }
                            .tag(name)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("Note") {
                    TextField("What's on your mind?", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("When") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Mood") {
                    Picker("Mood", selection: $mood) {
                        ForEach(1...5, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newMoment = LoopMoment(
                            id: UUID(),
                            date: date,
                            note: note,
                            imageName: imageName,
                            mood: mood
                        )
                        store.add(newMoment)
                        dismiss()
                    }
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct LoopEditMomentView: View {
    @EnvironmentObject var store: LoopStore
    @Environment(\.dismiss) private var dismiss

    let moment: LoopMoment

    @State private var note: String
    @State private var imageName: String
    @State private var date: Date
    @State private var mood: Int

    private let imageChoices = ["sample1", "sample2", "sample3", "sample4"]

    init(moment: LoopMoment) {
        self.moment = moment
        _note = State(initialValue: moment.note)
        _imageName = State(initialValue: moment.imageName)
        _date = State(initialValue: moment.date)
        _mood = State(initialValue: moment.mood)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Image") {
                    Picker("Image", selection: $imageName) {
                        ForEach(imageChoices, id: \.self) { name in
                            HStack {
                                Image(name)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                Text(name)
                            }
                            .tag(name)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("Note") {
                    TextField("What's on your mind?", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("When") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Mood") {
                    Picker("Mood", selection: $mood) {
                        ForEach(1...5, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Edit Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = moment
                        updated.date = date
                        updated.note = note
                        updated.imageName = imageName
                        updated.mood = mood
                        store.update(updated)
                        dismiss()
                    }
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct LoopSummaryView: View {
    @EnvironmentObject var store: LoopStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if store.moments.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("Nothing to summarize yet")
                                .font(.headline)
                            Text("Add moments to see your loop statistics.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 40)
                    } else {
                        summaryCards
                    }
                }
                .padding()
            }
            .navigationTitle("Summary")
        }
    }

    private var summaryCards: some View {
        VStack(spacing: 20) {
            summaryCard(
                title: "Total Moments",
                value: "\(store.moments.count)",
                systemImage: "number"
            )

            let thisWeek = store.moments.filter {
                $0.date >= Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            }
            summaryCard(
                title: "Last 7 Days",
                value: "\(thisWeek.count)",
                systemImage: "calendar"
            )

            let avgMood = store.moments.isEmpty ? 0 : Double(store.moments.map(\.mood).reduce(0, +)) / Double(store.moments.count)
            summaryCard(
                title: "Average Mood",
                value: String(format: "%.1f", avgMood),
                systemImage: "star"
            )

            let imageCounts = Dictionary(grouping: store.moments, by: { $0.imageName })
            let mostUsedImage = imageCounts.max { $0.value.count < $1.value.count }?.key ?? "sample1"
            summaryCard(
                title: "Most Used Image",
                value: mostUsedImage,
                systemImage: "photo"
            )
        }
    }

    private func summaryCard(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title2.weight(.bold))
            }
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}