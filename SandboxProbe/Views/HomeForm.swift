import SwiftUI

/// Add / edit sheet. Field order follows the requirement description.
struct HomeForm: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: HomeStore
    var editing: HomeItem?

    @State private var draft = HomeItem()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                TextField("note", text: $draft.note)
                }
            }
            .navigationTitle(editing == nil ? "New entry" : "Edit entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if editing == nil {
                            store.add(draft)
                        } else {
                            store.update(draft)
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let editing {
                    draft = editing
                }
            }
        }
    }
}
