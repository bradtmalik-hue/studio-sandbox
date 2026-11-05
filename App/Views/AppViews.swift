import SwiftUI
import Combine

// MARK: - 照片库主视图
struct AppPhotoLibraryView: View {
    @EnvironmentObject var store: AppAlbumStore
    @State private var selectedPhoto: AppPhoto?
    @State private var showingAddPhotoSheet = false

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if store.photos.isEmpty {
                    AppEmptyStateView(
                        icon: "photo.on.rectangle.angled",
                        title: "还没有照片",
                        message: "点击右上角 + 添加照片，开始打造你的图集收藏。"
                    )
                    .padding(.top, 80)
                } else {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(store.photos) { photo in
                            AppPhotoGridCell(photo: photo)
                                .onTapGesture {
                                    selectedPhoto = photo
                                }
                                .contextMenu {
                                    Button {
                                        store.toggleFavorite(photoID: photo.id)
                                    } label: {
                                        Label(
                                            photo.isFavorite ? "取消收藏" : "收藏",
                                            systemImage: photo.isFavorite ? "heart.slash" : "heart"
                                        )
                                    }
                                    Menu("添加到相册") {
                                        ForEach(store.albums) { album in
                                            Button(album.name) {
                                                store.addPhotoToAlbum(photoID: photo.id, albumID: album.id)
                                            }
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("图集收藏")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddPhotoSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPhotoSheet) {
                AppAddPhotoSheet()
            }
            .sheet(item: $selectedPhoto) { photo in
                AppPhotoDetailView(photo: photo)
            }
        }
    }
}

// MARK: - 照片网格单元格
struct AppPhotoGridCell: View {
    let photo: AppPhoto

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(photo.imageName)
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                )
            HStack {
                Text(photo.title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Spacer()
                if photo.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - 照片详情视图
struct AppPhotoDetailView: View {
    @EnvironmentObject var store: AppAlbumStore
    @Environment(\.dismiss) private var dismiss
    let photo: AppPhoto
    @State private var showingAlbumPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Image(photo.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(photo.title)
                            .font(.title2.bold())
                        Text(photo.date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if let album = store.albums.first(where: { $0.photoIDs.contains(photo.id) }) {
                            Label("所属相册：\(album.name)", systemImage: "folder")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    HStack(spacing: 20) {
                        Button {
                            store.toggleFavorite(photoID: photo.id)
                        } label: {
                            Label(
                                photo.isFavorite ? "已收藏" : "收藏",
                                systemImage: photo.isFavorite ? "heart.fill" : "heart"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            showingAlbumPicker = true
                        } label: {
                            Label("加入相册", systemImage: "folder.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("照片详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAlbumPicker) {
                AppAlbumPickerSheet(photoID: photo.id)
            }
        }
    }
}

// MARK: - 添加照片表单
struct AppAddPhotoSheet: View {
    @EnvironmentObject var store: AppAlbumStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedImageName = "sample1"
    @State private var selectedAlbumID: UUID?

    private let imageChoices = ["sample1", "sample2", "sample3", "sample4"]

    var body: some View {
        NavigationStack {
            Form {
                Section("照片") {
                    Picker("选择图片", selection: $selectedImageName) {
                        ForEach(imageChoices, id: \.self) { imageName in
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .tag(imageName)
                        }
                    }
                }

                Section("信息") {
                    TextField("标题", text: $title)
                    if !store.albums.isEmpty {
                        Picker("所属相册（可选）", selection: $selectedAlbumID) {
                            Text("无").tag(UUID?.none)
                            ForEach(store.albums) { album in
                                Text(album.name).tag(Optional(album.id))
                            }
                        }
                    }
                }

                Section {
                    Button("保存照片") {
                        let newPhoto = AppPhoto(
                            imageName: selectedImageName,
                            title: title.isEmpty ? "未命名照片" : title,
                            date: Date(),
                            albumID: selectedAlbumID ?? store.albums.first?.id,
                            isFavorite: false
                        )
                        store.addPhoto(newPhoto)
                        dismiss()
                    }
                    .disabled(title.isEmpty && selectedImageName.isEmpty)
                }
            }
            .navigationTitle("添加照片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 相册选择弹窗
struct AppAlbumPickerSheet: View {
    @EnvironmentObject var store: AppAlbumStore
    @Environment(\.dismiss) private var dismiss
    let photoID: UUID
    @State private var newAlbumName = ""
    @State private var showingCreateAlbum = false

    var body: some View {
        NavigationStack {
            List {
                if store.albums.isEmpty {
                    Text("暂无相册，请先创建")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(store.albums) { album in
                        Button {
                            store.addPhotoToAlbum(photoID: photoID, albumID: album.id)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                    .foregroundColor(.blue)
                                Text(album.name)
                                Spacer()
                                if album.photoIDs.contains(photoID) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showingCreateAlbum = true
                    } label: {
                        Label("新建相册", systemImage: "folder.badge.plus")
                    }
                }
            }
            .navigationTitle("选择相册")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCreateAlbum) {
                AppCreateAlbumSheet()
            }
        }
    }
}

// MARK: - 新建相册弹窗
struct AppCreateAlbumSheet: View {
    @EnvironmentObject var store: AppAlbumStore
    @Environment(\.dismiss) private var dismiss
    @State private var albumName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("相册名称") {
                    TextField("请输入相册名称", text: $albumName)
                }
                Section {
                    Button("创建") {
                        let newAlbum = AppAlbum(name: albumName, coverImageName: "sample1", photoIDs: [], createdAt: Date())
                        store.addAlbum(newAlbum)
                        dismiss()
                    }
                    .disabled(albumName.isEmpty)
                }
            }
            .navigationTitle("新建相册")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 相册列表视图
struct AppAlbumsView: View {
    @EnvironmentObject var store: AppAlbumStore
    @State private var showingCreateAlbum = false

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if store.albums.isEmpty {
                    AppEmptyStateView(
                        icon: "folder",
                        title: "还没有相册",
                        message: "点击右上角 + 新建相册，将照片分类收藏。"
                    )
                    .padding(.top, 80)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(store.albums) { album in
                            NavigationLink {
                                AppAlbumDetailView(album: album)
                            } label: {
                                AppAlbumGridCell(album: album)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    store.deleteAlbum(albumID: album.id)
                                } label: {
                                    Label("删除相册", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("相册")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateAlbum = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateAlbum) {
                AppCreateAlbumSheet()
            }
        }
    }
}

// MARK: - 相册网格单元格
struct AppAlbumGridCell: View {
    let album: AppAlbum

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(album.coverImageName)
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text("\(album.photoIDs.count) 张照片")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 相册详情视图
struct AppAlbumDetailView: View {
    @EnvironmentObject var store: AppAlbumStore
    let album: AppAlbum
    @State private var selectedPhoto: AppPhoto?

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 8)
    ]

    var body: some View {
        ScrollView {
            if album.photoIDs.isEmpty {
                AppEmptyStateView(
                    icon: "photo.on.rectangle",
                    title: "相册是空的",
                    message: "从照片库长按照片，或进入照片详情页加入本相册。"
                )
                .padding(.top, 80)
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(store.photos.filter { album.photoIDs.contains($0.id) }) { photo in
                        AppPhotoGridCell(photo: photo)
                            .onTapGesture {
                                selectedPhoto = photo
                            }
                            .contextMenu {
                                Button {
                                    store.toggleFavorite(photoID: photo.id)
                                } label: {
                                    Label(
                                        photo.isFavorite ? "取消收藏" : "收藏",
                                        systemImage: photo.isFavorite ? "heart.slash" : "heart"
                                    )
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(album.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedPhoto) { photo in
            AppPhotoDetailView(photo: photo)
        }
    }
}

// MARK: - 收藏视图
struct AppFavoritesView: View {
    @EnvironmentObject var store: AppAlbumStore
    @State private var selectedPhoto: AppPhoto?

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                let favoritePhotos = store.photos.filter { $0.isFavorite }
                if favoritePhotos.isEmpty {
                    AppEmptyStateView(
                        icon: "heart",
                        title: "还没有收藏",
                        message: "在照片库点击照片，或长按照片选择收藏。"
                    )
                    .padding(.top, 80)
                } else {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(favoritePhotos) { photo in
                            AppPhotoGridCell(photo: photo)
                                .onTapGesture {
                                    selectedPhoto = photo
                                }
                                .contextMenu {
                                    Button {
                                        store.toggleFavorite(photoID: photo.id)
                                    } label: {
                                        Label("取消收藏", systemImage: "heart.slash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("收藏")
            .sheet(item: $selectedPhoto) { photo in
                AppPhotoDetailView(photo: photo)
            }
        }
    }
}

// MARK: - 空状态引导视图
struct AppEmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text(title)
                .font(.title2.bold())
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - 预览
#Preview {
    AppPhotoLibraryView()
        .environmentObject(AppAlbumStore())
}