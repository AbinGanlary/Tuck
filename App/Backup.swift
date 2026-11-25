import Security
import SwiftUI
import UniformTypeIdentifiers

/// Every folder plus the photos they use (photo icons and backgrounds), in one JSON file. App Store
/// icons aren't included: Tuck downloads them again after a restore. A fresh install (a new signing,
/// say) starts with no folders, so this is how they come back.
struct Backup: Codable {
    static let currentFormat = 1

    var format = Backup.currentFormat
    var created = Date()
    var library: Library
    var photos: [String: Data] = [:]   // photo id → JPEG (base64 in the file)

    init(library: Library) {
        self.library = library
        for id in library.photoIDs {
            photos[id.uuidString] = SharedBlobs.read(account: IconCache.photoAccount(id))
        }
    }

    var fileName: String { "Tuck backup \(created.formatted(.iso8601.year().month().day()))" }

    /// Puts the photos back under their ids, so the restored folders find them. The number that failed.
    func restorePhotos() -> Int {
        photos.filter { id, data in
            guard let uuid = UUID(uuidString: id) else { return true }
            return SharedBlobs.write(data, account: IconCache.photoAccount(uuid)) != errSecSuccess
        }.count
    }
}

extension Library {
    /// Every photo the folders use: photo icons and widget backgrounds.
    var photoIDs: Set<UUID> {
        var ids = Set(folders.compactMap(\.backgroundPhoto))
        for app in folders.flatMap(\.apps) {
            if case .photo(let id) = app.icon { ids.insert(id) }
        }
        return ids
    }
}

/// The backup as a file for the Files save dialog.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let backup: Backup

    init(backup: Backup) {
        self.backup = backup
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        backup = try Backup.decode(data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return FileWrapper(regularFileWithContents: try encoder.encode(backup))
    }
}

extension Backup {
    static func decode(_ data: Data) throws -> Backup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(Backup.self, from: data)
        guard backup.format <= currentFormat else {
            throw CocoaError(.fileReadUnsupportedScheme, userInfo: [
                NSLocalizedDescriptionKey: "This backup is from a newer Tuck. Update Tuck first."])
        }
        return backup
    }

    /// Reads a backup the user picked in Files (outside Tuck's sandbox, so access is asked for).
    static func read(_ url: URL) throws -> Backup {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        return try decode(Data(contentsOf: url))
    }
}

/// About Tuck → Backup: save everything to Files, or replace the folders with a saved backup.
struct BackupSection: View {
    @EnvironmentObject private var model: LibraryModel
    @State private var exporting: BackupDocument?
    @State private var importing = false
    @State private var pending: Backup?   // picked, waiting for the replace confirmation
    @State private var message: String?

    var body: some View {
        Section {
            Button("Back up to Files", systemImage: "square.and.arrow.up") {
                exporting = BackupDocument(backup: Backup(library: model.library))
            }
            .disabled(model.library.folders.isEmpty)
            .fileExporter(isPresented: Binding(get: { exporting != nil }, set: { if !$0 { exporting = nil } }),
                          document: exporting, contentType: .json,
                          defaultFilename: exporting?.backup.fileName ?? "Tuck backup") { result in
                switch result {
                case .success: message = "Backup saved."
                case .failure(let error): message = "Couldn't save the backup: \(error.localizedDescription)"
                }
            }

            Button("Restore from backup", systemImage: "square.and.arrow.down") { importing = true }
                .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                    do {
                        pending = try Backup.read(result.get())
                    } catch {
                        message = "Couldn't read that file: \(error.localizedDescription)"
                    }
                }
        } header: {
            Text("Backup")
        } footer: {
            Text(message ?? "Saves every folder, your settings and your photos in one file. App Store icons download again after a restore.")
        }
        .confirmationDialog(restoreQuestion, isPresented: Binding(
            get: { pending != nil }, set: { if !$0 { pending = nil } }), titleVisibility: .visible
        ) {
            Button("Replace folders", role: .destructive) {
                guard let backup = pending else { return }
                let failed = model.restore(backup)
                message = "Restored \(backup.library.folders.count) folders"
                    + (failed > 0 ? ", but \(failed) photos couldn't be saved." : ".")
            }
        } message: {
            Text("Your current folders are replaced, and the widgets show the restored ones.")
        }
    }

    private var restoreQuestion: String {
        guard let backup = pending else { return "" }
        let date = backup.created.formatted(date: .abbreviated, time: .shortened)
        return "Restore \(backup.library.folders.count) folders from \(date)?"
    }
}
