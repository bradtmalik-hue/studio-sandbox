import SwiftUI
import Foundation
import Combine

// MARK: - 收藏列表视图
struct AppCollectionView: View {
    @EnvironmentObject var store: AppStore

    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if store.images.isEmpty {
                    ContentUnavailableView(
                        "收藏夹还是空的",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("点击下方“添加”按钮，把喜欢的图片收进来。")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(store.images) { item in
                                NavigationLink {
                                    AppImageDetailView(item: item)
                                } label: {
                                    AppImageCard(item: item)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        delete(item)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                            }
                            .onDelete(perform: deleteItems)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("图集收藏")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !store.images.isEmpty {
                        EditButton()
                    }
                }
            }
        }
    }

    private func delete(_ item: AppImageItem) {
        if let index = store.images.firstIndex(where: { $0.id == item.id }) {
            store.images.remove(at: index)
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        store.images.remove(atOffsets: offsets)
    }
}

// MARK: - 单张图片卡片
struct AppImageCard: View {
    let item: AppImageItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(item.imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(item.title)
                .font(.headline)
                .lineLimit(1)

            Text(item.date, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - 添加图片视图
struct AppAddImageView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var selectedImage = "sample1"

    private let sampleImages = ["sample1", "sample2", "sample3", "sample4"]

    var body: some View {
        NavigationStack {
            Form {
                Section("选择图片") {
                    Picker("图片", selection: $selectedImage) {
                        ForEach(sampleImages, id: \.self) { name in
                            Label(name, systemImage: "photo").tag(name)
                        }
                    }
                    .pickerStyle(.menu)

                    HStack {
                        Spacer()
                        Image(selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Spacer()
                    }
                }

                Section("标题") {
                    TextField("给图片起个名字", text: $title)
                }

                Section {
                    Button {
                        addImage()
                    } label: {
                        Text("添加到收藏")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("添加图片")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.pink)
        }
    }

    private func addImage() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newItem = AppImageItem(
            title: trimmed,
            imageName: selectedImage,
            date: Date()
        )
        store.images.append(newItem)

        title = ""
        selectedImage = "sample1"
        dismiss()
    }
}

// MARK: - 图片详情视图
struct AppImageDetailView: View {
    @EnvironmentObject var store: AppStore
    let item: AppImageItem

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.title2.bold())

                    Text(item.date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(role: .destructive) {
                    deleteItem()
                } label: {
                    Label("从收藏中删除", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()
        }
        .navigationTitle("图片详情")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deleteItem() {
        if let index = store.images.firstIndex(where: { $0.id == item.id }) {
            store.images.remove(at: index)
        }
    }
}

// MARK: - 设置视图
struct AppSettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("关于") {
                    LabeledContent("App 名称", value: "图集收藏")
                    LabeledContent("版本", value: "1.0")
                }

                Section {
                    Text("把喜欢的图片都收进来。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
        }
    }
}

// MARK: - 兼容别名，方便入口视图引用常见命名
typealias AppLibraryView = AppCollectionView
typealias AppGalleryView = AppCollectionView
typealias AppHomeView = AppCollectionView
typealias AppAddView = AppAddImageView
typealias AppImagePickerView = AppAddImageView