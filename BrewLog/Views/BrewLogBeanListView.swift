import SwiftUI

struct BrewLogBeanListView: View {
    @EnvironmentObject var store: BrewLogStore
    @State private var showingAddSheet = false
    @State private var editingBean: BrewLogBean?
    @State private var showingEditSheet = false

    var body: some View {
        NavigationView {
            List {
                ForEach(store.beans, id: \.name) { bean in
                    Button {
                        editingBean = bean
                        showingEditSheet = true
                    } label: {
                        BeanRow(bean: bean)
                    }
                }
                .onDelete(perform: deleteBeans)
            }
            .navigationTitle("豆单")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                BeanFormView(mode: .add) { newBean in
                    store.beans.append(newBean)
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let bean = editingBean {
                    BeanFormView(mode: .edit(bean)) { updatedBean in
                        if let index = store.beans.firstIndex(where: { $0.name == bean.name }) {
                            store.beans[index] = updatedBean
                        }
                    }
                }
            }
        }
    }

    private func deleteBeans(at offsets: IndexSet) {
        store.beans.remove(atOffsets: offsets)
    }
}

private struct BeanRow: View {
    let bean: BrewLogBean

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(bean.name)
                .font(.headline)
                .foregroundColor(.primary)
            if !bean.roaster.isEmpty {
                Text(bean.roaster)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if !bean.notes.isEmpty {
                Text(bean.notes)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

private enum BeanFormMode {
    case add
    case edit(BrewLogBean)
}

private struct BeanFormView: View {
    let mode: BeanFormMode
    let onSave: (BrewLogBean) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var roaster: String = ""
    @State private var notes: String = ""

    private var isEditing: Bool {
        if case .edit = mode {
            return true
        }
        return false
    }

    private var originalBean: BrewLogBean? {
        if case .edit(let bean) = mode {
            return bean
        }
        return nil
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("名称")) {
                    TextField("豆子名称", text: $name)
                        .disabled(isEditing)
                }
                Section(header: Text("烘焙商")) {
                    TextField("烘焙商", text: $roaster)
                }
                Section(header: Text("备注")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isEditing ? "编辑豆子" : "新增豆子")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveBean()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let bean = originalBean {
                    name = bean.name
                    roaster = bean.roaster
                    notes = bean.notes
                }
            }
        }
    }

    private func saveBean() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let finalName: String
        if isEditing, let bean = originalBean {
            finalName = bean.name
        } else {
            finalName = trimmedName
        }
        let newBean = BrewLogBean(
            name: finalName,
            roaster: roaster.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        onSave(newBean)
        dismiss()
    }
}