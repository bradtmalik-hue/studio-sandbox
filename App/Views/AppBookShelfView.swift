import SwiftUI

struct AppBookShelfView: View {
    @EnvironmentObject var store: AppQuoteStore

    var body: some View {
        NavigationStack {
            Group {
                if store.bookGroups.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 56))
                            .foregroundColor(.secondary)
                        Text("还没有摘录")
                            .font(.title2.bold())
                        Text("去“记一句”添加你的第一条摘录吧")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    List {
                        ForEach(store.bookGroups) { group in
                            NavigationLink {
                                AppBookDetailView(book: group)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(group.bookName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("\(group.quotes.count) 条摘录")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("书库")
        }
    }
}