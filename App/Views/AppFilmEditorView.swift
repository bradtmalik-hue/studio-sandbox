import SwiftUI

struct AppFilmEditorView: View {
    @EnvironmentObject private var store: AppFilmStore
    @Environment(\.dismiss) private var dismiss

    let record: AppFilmRecord

    @State private var title: String
    @State private var rating: Double
    @State private var watchDate: Date

    init(record: AppFilmRecord) {
        self.record = record
        _title = State(initialValue: record.title)
        _rating = State(initialValue: record.rating)
        _watchDate = State(initialValue: record.watchDate)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedTitle.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("片名") {
                    TextField("例如：沙丘", text: $title)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }

                Section("星级") {
                    AppStarRatingView()
                }

                Section("看片日期") {
                    DatePicker(
                        "日期",
                        selection: $watchDate,
                        displayedComponents: .date
                    )
                }
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        var updated = record
        updated.title = trimmedTitle
        updated.rating = rating
        updated.watchDate = watchDate
        store.update(updated)
        dismiss()
    }
}