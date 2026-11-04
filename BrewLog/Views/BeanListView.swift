import SwiftUI

struct BeanListView: View {
    @EnvironmentObject private var store: BrewLogStore
    @State private var showingAddSheet = false
    @State private var editingBean: BrewBean?

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.beans) { bean in
                    Button {
                        editingBean = bean
                    } label: {
                        BeanRow(bean: bean)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteBeans)
            }
            .navigationTitle("豆单")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    BeanFormView(bean: nil) { newBean in
                        store.beans.append(newBean)
                        store.saveBeans()
                    }
                }
            }
            .sheet(item: $editingBean) { bean in
                NavigationStack {
                    BeanFormView(bean: bean) { updatedBean in
                        if let index = store.beans.firstIndex(where: { $0.id == updatedBean.id }) {
                            store.beans[index] = updatedBean
                            store.saveBeans()
                        }
                    }
                }
            }
        }
        .tint(.orange)
    }

    private func deleteBeans(at offsets: IndexSet) {
        store.beans.remove(atOffsets: offsets)
        store.saveBeans()
    }
}

private struct BeanRow: View {
    let bean: BrewBean

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(bean.name)
                .font(.headline)
            if !bean.roaster.isEmpty {
                Text(bean.roaster)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !bean.notes.isEmpty {
                Text(bean.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct BeanFormView: View {
    let bean: BrewBean?
    let onSave: (BrewBean) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var roaster: String
    @State private var notes: String

    init(bean: BrewBean?, onSave: @escaping (BrewBean) -> Void) {
        self.bean = bean
        self.onSave = onSave
        _name = State(initialValue: bean?.name ?? "")
        _roaster = State(initialValue: bean?.roaster ?? "")
        _notes = State(initialValue: bean?.notes ?? "")
    }

    var body: some View {
        Form {
            Section("豆子信息") {
                TextField("名称", text: $name)
                TextField("烘焙师", text: $roaster)
            }
            Section("备注") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle(bean == nil ? "新增豆子" : "编辑豆子")
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
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let newBean: BrewBean
        if let bean = bean {
            newBean = BrewBean(id: bean.id, name: trimmedName, roaster: roaster, notes: notes)
        } else {
            newBean = BrewBean(name: trimmedName, roaster: roaster, notes: notes)
        }
        onSave(newBean)
        dismiss()
    }
}

#Preview {
    BeanListView()
        .environmentObject(BrewLogStore())
}