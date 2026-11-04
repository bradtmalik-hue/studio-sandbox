import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: HomeStore
    @State private var showingForm = false
    @State private var editing: HomeItem?

    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                if store.items.isEmpty {
                    Text("list")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 60)
                }
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(store.items) { item in
                        Button {
                            editing = item; showingForm = true
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                    Text(item.note)
                                        .font(.headline)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(.quaternary.opacity(0.3),
                                        in: RoundedRectangle(cornerRadius: 17))
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) { store.remove(item) } label: {
                                Text("删除")
                            }
                        }
                    }
                }
                .padding(11)
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editing = nil; showingForm = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                HomeForm(store: store, editing: editing)
            }
        }
    }
}
