import SwiftUI

struct AppPage2: View {
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    AppPage2TextField(title: "Name", placeholder: "Enter name")
                    AppPage2TextField(title: "Description", placeholder: "Enter description")
                    AppPage2QuantityStepper()
                }
            }
            .navigationTitle("Page 2")
        }
    }
}

struct AppPage2TextField: View {
    let title: String
    let placeholder: String
    @State private var text: String = ""

    init(title: String, placeholder: String) {
        self.title = title
        self.placeholder = placeholder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.vertical, 4)
    }
}

struct AppPage2QuantityStepper: View {
    @State private var quantity = 0

    var body: some View {
        Stepper("Quantity: \(quantity)", value: $quantity, in: 0...100)
            .padding(.vertical, 4)
    }
}

struct AppPage2_Previews: PreviewProvider {
    static var previews: some View {
        AppPage2()
    }
}
