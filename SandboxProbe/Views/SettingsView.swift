import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: SettingsStore
    @State private var showingForm = false
    @State private var editing: SettingsItem?

    var body: some View {
        NavigationStack {
            List {
                if store.items.isEmpty {
                    Text("t")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                ForEach(store.items) { item in
                    Button {
                        editing = item
                        showingForm = true
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                        Text(item.flag ? "flag" : "-")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            store.remove(item)
                        } label: {
                            Text("Delete")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editing = nil
                        showingForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                SettingsForm(store: store, editing: editing)
            }
        }
    }
}
