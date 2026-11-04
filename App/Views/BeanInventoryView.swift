import SwiftUI

private struct BeanItem: Identifiable {
    let id = UUID()
    var name: String
    var origin: String
    var roastLevel: String
    var quantityInGrams: Int
}

struct BeanInventoryView: View {
    @State private var beans = [
        BeanItem(name: "Yirgacheffe", origin: "Ethiopia", roastLevel: "Light Roast", quantityInGrams: 500),
        BeanItem(name: "Mandheling", origin: "Indonesia", roastLevel: "Dark Roast", quantityInGrams: 250)
    ]
    @State private var showingAddBean = false
    @State private var newBeanName = ""
    @State private var newBeanOrigin = ""
    @State private var newBeanRoastLevel = "Medium Roast"
    @State private var newBeanQuantity = "0"

    var body: some View {
        NavigationView {
            List {
                ForEach(beans) { bean in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bean.name)
                            .font(.headline)
                        Text("\(bean.origin) · \(bean.roastLevel)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(bean.quantityInGrams) g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete(perform: deleteBeans)
            }
            .navigationTitle("Bean Inventory")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddBean = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBean) {
                addBeanSheet
            }
        }
    }

    private var addBeanSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Bean Details")) {
                    TextField("Name", text: $newBeanName)
                    TextField("Origin", text: $newBeanOrigin)
                    TextField("Roast Level", text: $newBeanRoastLevel)
                    TextField("Quantity (g)", text: $newBeanQuantity)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("New Bean")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddBean = false
                        clearNewBeanFields()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addBean()
                        showingAddBean = false
                        clearNewBeanFields()
                    }
                    .disabled(newBeanName.isEmpty || Int(newBeanQuantity) == nil)
                }
            }
        }
    }

    private func addBean() {
        guard let quantity = Int(newBeanQuantity), !newBeanName.isEmpty else { return }
        let bean = BeanItem(
            name: newBeanName,
            origin: newBeanOrigin.isEmpty ? "Unknown" : newBeanOrigin,
            roastLevel: newBeanRoastLevel.isEmpty ? "Medium Roast" : newBeanRoastLevel,
            quantityInGrams: quantity
        )
        beans.append(bean)
    }

    private func deleteBeans(at offsets: IndexSet) {
        beans.remove(atOffsets: offsets)
    }

    private func clearNewBeanFields() {
        newBeanName = ""
        newBeanOrigin = ""
        newBeanRoastLevel = "Medium Roast"
        newBeanQuantity = "0"
    }
}

struct BeanInventoryView_Previews: PreviewProvider {
    static var previews: some View {
        BeanInventoryView()
    }
}