import SwiftUI

/// Add / edit sheet. Field order follows the requirement description.
struct SettingsForm: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: SettingsStore
    var editing: SettingsItem?

    @State private var draft = SettingsItem()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                Toggle("flag", isOn: $draft.flag)
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
