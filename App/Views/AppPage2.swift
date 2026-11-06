import SwiftUI

struct AppPage2View: View {
    @EnvironmentObject private var store: AppMedicineStore

    @State private var name = ""
    @State private var location = ""
    @State private var expiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var quantity = 1
    @State private var showingSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    AppPage2InfoCard()

                    AppPage2FormCard {
                        VStack(spacing: 16) {
                            AppPage2TextField(
                                title: "药品名称",
                                text: $name,
                                placeholder: "例如：布洛芬缓释胶囊"
                            )

                            DatePicker(
                                selection: $expiryDate,
                                in: Date()...,
                                displayedComponents: .date
                            ) {
                                Text("有效期")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)

                            AppPage2TextField(
                                title: "存放位置",
                                text: $location,
                                placeholder: "例如：客厅药箱第一格"
                            )

                            AppPage2QuantityStepper(quantity: $quantity)
                        }
                    }

                    Button(action: save) {
                        Text("保存并登记")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(
                        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color.gray.opacity(0.06).ignoresSafeArea())
            .navigationTitle("添加一盒药")
            .environment(\.locale, Locale(identifier: "zh_CN"))
            .contentMargins(.bottom, 96, for: .scrollContent)
            .alert("已登记", isPresented: $showingSuccess) {
                Button("好", role: .cancel) { }
            } message: {
                Text("这盒药已经加入家庭药箱。")
            }
        }
    }

    func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)

        let newMedicine = AppMedicine(
            name: trimmedName,
            expiryDate: expiryDate,
            location: trimmedLocation,
            quantity: quantity
        )

        store.medicines.append(newMedicine)
        store.save()

        name = ""
        location = ""
        quantity = 1
        expiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        showingSuccess = true
    }
}

private struct AppPage2InfoCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "pills.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text("登记新药")
                    .font(.headline)

                Text("填写药名、有效期和存放位置，方便以后按效期先用。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            Color.accentColor.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
}

private struct AppPage2FormCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                Color.primary.opacity(0.04),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
    }
}

private struct AppPage2TextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    Color.primary.opacity(0.05),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
        }
    }
}

private struct AppPage2QuantityStepper: View {
    @Binding var quantity: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("数量")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(quantity) 盒")
                    .font(.body)
            }

            Spacer()

            Stepper("", value: $quantity, in: 1...30)
                .labelsHidden()
        }
    }
}