import SwiftUI

struct AppFilmDetailEditView: View {
    @EnvironmentObject private var store: AppFilmLibraryStore
    @Environment(\.dismiss) private var dismiss
    private let originalRecord: AppFilmRecord

    @State private var title: String
    @State private var rating: Int
    @State private var watchDate: Date

    init(record: AppFilmRecord) {
        self.originalRecord = record
        _title = State(initialValue: record.title)
        _rating = State(initialValue: record.starRating)
        _watchDate = State(initialValue: record.watchDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ticketCard
                    saveButton
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private var ticketCard: some View {
        VStack(spacing: 20) {
            titleField
            ratingField
            dateField
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("片名")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("片名", text: $title)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .font(.title3.weight(.semibold))
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var ratingField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("评分")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(index <= rating ? Color.yellow : Color.secondary)
                        .onTapGesture {
                            rating = index
                        }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("看片日期")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            DatePicker("看片日期", selection: $watchDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var saveButton: some View {
        Button {
            saveChanges()
        } label: {
            Text("保存修改")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(valid ? Color.accentColor : Color.secondary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(!valid)
    }

    private var valid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (1...5).contains(rating)
    }

    private func saveChanges() {
        guard valid else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let updated = AppFilmRecord(
            id: originalRecord.id,
            title: trimmedTitle,
            starRating: rating,
            watchDate: watchDate,
            createdAt: originalRecord.createdAt
        )
        store.update(updated)
        dismiss()
    }
}