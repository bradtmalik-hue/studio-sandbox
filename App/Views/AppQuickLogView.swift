import SwiftUI

struct AppQuickLogView: View {
    @EnvironmentObject private var store: AppFilmStore

    @State private var title: String = ""
    @State private var rating: Double = 3.0
    @State private var watchDate: Date = Date()
    @State private var saveTrigger: Int = 0
    @State private var showingSaveError: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    quickLogCard
                }
                .padding(20)
            }
            .navigationTitle("记一部")
            .navigationBarTitleDisplayMode(.large)
            .sensoryFeedback(.success, trigger: saveTrigger)
            .alert("还没填写片名", isPresented: $showingSaveError) {
                Button("好", role: .cancel) {}
            } message: {
                Text("请先输入片名，再保存这部片子。")
            }
        }
    }

    private var quickLogCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("快速记录一部电影", systemImage: "film.stack")
                .font(.headline)

            TextField("片名，例如《沙丘》", text: $title)
                .font(.title3)
                .padding(14)
                .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 14))
                .submitLabel(.done)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("星级")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(String(format: "%.1f 分", rating))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Slider(value: $rating, in: 0...5, step: 0.5)
                    .tint(themeColor)
                    .sensoryFeedback(.selection, trigger: rating)

                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: starSymbolName(for: index, rating: rating))
                            .foregroundColor(.yellow)
                    }
                }
                .accessibilityHidden(true)
            }

            DatePicker("看片日期", selection: $watchDate, displayedComponents: .date)
                .datePickerStyle(.compact)

            Button(action: save) {
                Label("保存这部片", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(themeColor)
            .disabled(trimmedTitle.isEmpty)
        }
        .padding(20)
        .background(Color.white.opacity(0.25), in: RoundedRectangle(cornerRadius: 24))
        .background(themeColor.gradient, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.10), radius: 14, y: 8)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var themeColor: Color {
        guard !trimmedTitle.isEmpty else {
            return Color(white: 0.93)
        }

        let scalarSum = trimmedTitle.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let hue = Double(scalarSum % 360) / 360.0
        return Color(hue: hue, saturation: 0.34, brightness: 0.96)
    }

    private func save() {
        guard !trimmedTitle.isEmpty else {
            showingSaveError = true
            return
        }

        let record = AppFilmRecord(title: trimmedTitle, rating: rating, watchDate: watchDate)
        store.add(record)

        title = ""
        rating = 3.0
        watchDate = Date()
        saveTrigger += 1
    }

    private func starSymbolName(for index: Int, rating: Double) -> String {
        let upperBound = Double(index) + 1.0
        let lowerBound = Double(index)

        if rating >= upperBound {
            return "star.fill"
        } else if rating >= lowerBound + 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}