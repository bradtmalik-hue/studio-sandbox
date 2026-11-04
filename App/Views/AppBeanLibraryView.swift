import SwiftUI
import Foundation

struct AppBeanLibraryView: View {
    @EnvironmentObject private var beanStore: AppBeanStore
    @State private var showingAddBean = false

    var body: some View {
        List {
            ForEach(beanStore.beans) { bean in
                AppBeanRow(bean: bean)
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("咖啡豆")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddBean = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddBean) {
            AddAppBeanView()
        }
    }

    private func delete(at offsets: IndexSet) {
        beanStore.beans.remove(atOffsets: offsets)
    }
}

private struct AppBeanRow: View {
    let bean: AppBean

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(bean.name)
                    .font(.headline)
                Spacer()
                Text("\(bean.daysSinceRoast) 天")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            ProgressView(value: bean.remainingRatio)
            HStack {
                Text("\(bean.remainingGrams, specifier: "%.0f") g 剩余")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(bean.remainingRatio * 100, specifier: "%.0f")%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AddAppBeanView: View {
    @EnvironmentObject private var beanStore: AppBeanStore
    @Environment(\.presentationMode) private var presentationMode

    @State private var name = ""
    @State private var roastDate = Date()
    @State private var initialGrams: Double = 100

    var body: some View {
        NavigationView {
            Form {
                TextField("名称", text: $name)
                DatePicker("烘焙日期", selection: $roastDate, displayedComponents: .date)
                TextField("初始克重", value: $initialGrams, formatter: numberFormatter)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("新咖啡豆")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let newBean = AppBean(
                            id: UUID(),
                            name: name,
                            roastDate: roastDate,
                            initialGrams: initialGrams,
                            remainingGrams: initialGrams
                        )
                        beanStore.beans.append(newBean)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty || initialGrams <= 0)
                }
            }
        }
    }
}

private let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter
}()