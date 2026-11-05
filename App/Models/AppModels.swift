import Foundation
import Combine

enum AppImageLibrary {
    static let sampleImageNames = ["sample1", "sample2", "sample3", "sample4"]
}

struct AppPhoto: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var imageName: String
    var note: String = ""
    var createdAt: Date = Date()
}

struct AppAlbum: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var detail: String = ""
    var coverImageName: String?
    var photos: [AppPhoto] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

final class AppAlbumStore: ObservableObject {
    @Published var albums: [AppAlbum] = []
    
    private let fileURL: URL
    
    init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documentsDirectory.appendingPathComponent("albums.json")
        load()
    }
    
    func addAlbum(name: String, detail: String = "", coverImageName: String? = nil) {
        let album = AppAlbum(name: name, detail: detail, coverImageName: coverImageName)
        albums.append(album)
        save()
    }
    
    func deleteAlbum(_ album: AppAlbum) {
        albums.removeAll { $0.id == album.id }
        save()
    }
    
    func updateAlbum(_ album: AppAlbum) {
        guard let index = albums.firstIndex(where: { $0.id == album.id }) else { return }
        var updatedAlbum = album
        updatedAlbum.updatedAt = Date()
        albums[index] = updatedAlbum
        save()
    }
    
    func addPhoto(to albumID: UUID, imageName: String, note: String = "") {
        guard let index = albums.firstIndex(where: { $0.id == albumID }) else { return }
        let photo = AppPhoto(imageName: imageName, note: note)
        albums[index].photos.append(photo)
        albums[index].updatedAt = Date()
        save()
    }
    
    func removePhoto(from albumID: UUID, photoID: UUID) {
        guard let index = albums.firstIndex(where: { $0.id == albumID }) else { return }
        albums[index].photos.removeAll { $0.id == photoID }
        albums[index].updatedAt = Date()
        save()
    }
    
    func album(with id: UUID) -> AppAlbum? {
        albums.first(where: { $0.id == id })
    }
    
    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(albums)
            try data.write(to: fileURL)
        } catch {
            // 保存失败时静默处理
        }
    }
    
    private func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            albums = try decoder.decode([AppAlbum].self, from: data)
        } catch {
            albums = []
        }
    }
}