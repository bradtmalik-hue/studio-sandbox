import SwiftUI

struct BrewLogBeanListView: View {
    @EnvironmentObject private var store: BrewLogStore
    @State private var showingAddBeanSheet = false

    private var activeBeans: [BrewLogBean] {
        store.beans.filter { !$0.isArchived }
    }

    var body: some View {
        NavigationStack {
            List {
                if activeBeans.isEmpty {
                    ContentUnavailableView(
                        "No Beans",
                        systemImage: "cup.and.saucer",
                        description: Text("Add a coffee bean to start brewing.")
                    )
                } else {
                    ForEach(activeBeans) { bean in
                        BrewLogBeanRow(bean: bean, archiveAction: {
                            store.archiveBean(bean)
                        })
                    }
                }
            }
            .navigationTitle("Beans")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddBeanSheet = true
                    } label: {
                        Label("Add Bean", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBeanSheet) {
                BrewLogAddBeanSheet()
                    .environmentObject(store)
            }
        }
    }
}

struct BrewLogBeanRow: View {
    let bean: BrewLogBean
    let archiveAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(bean.name)
                .font(.headline)
            if !bean.roaster.isEmpty {
                Text(bean.roaster)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if !bean.notes.isEmpty {
                Text(bean.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                archiveAction()
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
            .tint(.orange)
        }
    }
}

struct BrewLogAddBeanSheet: View {
    @EnvironmentObject private var store: BrewLogStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var roaster = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Bean Details") {
                    TextField("Name", text: $name)
                    TextField("Roaster", text: $roaster)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Bean")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty else { return }
                        let newBean = BrewLogBean(
                            id: UUID(),
                            name: trimmedName,
                            roaster: roaster.trimmingCharacters(in: .whitespacesAndNewlines),
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                            isArchived: false
                        )
                        store.addBean(newBean)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}