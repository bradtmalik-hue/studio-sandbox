import SwiftUI

struct RecordFilmView: View {
    @EnvironmentObject private var store: AppFilmLibraryStore

    @State private var title: String = ""
    @State private var starRating: Int = 0
    @State private var watchDate: Date = Date()
    @FocusState private var isTitleFocused: Bool

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedTitle.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ticketCard

                    if trimmedTitle.isEmpty {
                        Label("先写下片名，再点亮星星", systemImage: "film")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("记一部")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        isTitleFocused = false
                    }
                }
            }
        }
    }

    private var ticketCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            TextField("片名", text: $title)
                .font(.title2.weight(.semibold))
                .textInputAutocapitalization(.never)
                .submitLabel(.done)
                .focused($isTitleFocused)
                .padding(14)
                .background(
                    Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("星级")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                AppStarRatingView(rating: $starRating)
            }

            DatePicker("看片日期", selection: $watchDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .font(.subheadline)

            Button(action: save) {
                Label(canSave ? "存入片单" : "先填写片名", systemImage: "ticket.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canSave)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, y: 6)
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: "ticket")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
                .padding(16)
        }
    }

    private func save() {
        guard canSave else { return }

        let record = AppFilmRecord(
            title: trimmedTitle,
            starRating: starRating,
            watchDate: watchDate
        )

        store.add(record)

        title = ""
        starRating = 0
        watchDate = Date()
        isTitleFocused = false
    }
}