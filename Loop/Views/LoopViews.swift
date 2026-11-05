import SwiftUI

// MARK: - Moment Card
struct LoopMomentCard: View {
    let moment: LoopMoment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(moment.imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack {
                Text(moment.date, format: .dateTime.month().day().year())
                    .font(.caption)
                Text(moment.date, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(moment.note)
                .font(.body)
                .lineLimit(3)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// MARK: - Timeline View
struct LoopTimelineView: View {
    @EnvironmentObject var store: LoopStore
    @State private var showingCompose = false

    var body: some View {
        NavigationStack {
            Group {
                if store.moments.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(store.moments) { moment in
                                LoopMomentCard(moment: moment)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteMoment(moment)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Loop")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCompose = true
                    } label: {
                        Label("Add Moment", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCompose) {
                LoopComposeView()
                    .environmentObject(store)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No moments yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Capture a moment to start your loop.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showingCompose = true
            } label: {
                Label("Add Your First Moment", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func deleteMoment(_ moment: LoopMoment) {
        if let index = store.moments.firstIndex(where: { $0.id == moment.id }) {
            store.delete(at: IndexSet(integer: index))
        }
    }
}

// MARK: - Compose View
struct LoopComposeView: View {
    @EnvironmentObject var store: LoopStore
    @Environment(\.dismiss) private var dismiss

    @State private var note = ""
    @State private var selectedImageName = "sample1"

    private let availableImages = ["sample1", "sample2", "sample3", "sample4"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Moment") {
                    TextField("What's happening?", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Photo") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(availableImages, id: \.self) { imageName in
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                selectedImageName == imageName ? Color.accentColor : Color.clear,
                                                lineWidth: 3
                                            )
                                    )
                                    .onTapGesture {
                                        selectedImageName = imageName
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
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
                        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        let moment = LoopMoment(
                            id: UUID(),
                            date: Date(),
                            note: trimmedNote,
                            imageName: selectedImageName
                        )
                        store.add(moment)
                        dismiss()
                    }
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}