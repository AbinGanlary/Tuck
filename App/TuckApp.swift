import SwiftUI
import WidgetKit

@main
struct TuckApp: App {
    @StateObject private var model = LibraryModel()

    var body: some Scene {
        WindowGroup {
            FoldersView()
                .environmentObject(model)
                .tint(Theme.cognac)
                .onOpenURL { handle($0) }
                .task { await model.shareIcons() }
        }
    }

    /// tuck://bundle?id=<bundleId>: fallback route that opens an app through Tuck.
    private func handle(_ url: URL) {
        guard url.host == "bundle",
              let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                  .queryItems?.first(where: { $0.name == "id" })?.value
        else { return }
        PrivateApps.openBundle(id)
    }
}

/// The folders, loaded once and saved (and widgets refreshed) after every change.
@MainActor
final class LibraryModel: ObservableObject {
    @Published private(set) var library = Store.load()
    @Published var errorMessage: String?

    func folder(_ id: UUID) -> Folder? {
        library.folders.first { $0.id == id }
    }

    func save(_ folder: Folder) {
        change { library in
            if let i = library.folders.firstIndex(where: { $0.id == folder.id }) {
                library.folders[i] = folder
            } else {
                library.folders.append(folder)
            }
        }
    }

    func modify(_ id: UUID, _ edit: (inout Folder) -> Void) {
        change { library in
            if let i = library.folders.firstIndex(where: { $0.id == id }) {
                edit(&library.folders[i])
            }
        }
    }

    /// Moves a folder earlier (-1) or later (+1). Its position is the widget that shows it.
    func move(_ id: UUID, by offset: Int) {
        change { library in
            guard let i = library.folders.firstIndex(where: { $0.id == id }),
                  library.folders.indices.contains(i + offset) else { return }
            library.folders.swapAt(i, i + offset)
        }
    }

    func delete(_ id: UUID) {
        change { $0.folders.removeAll { $0.id == id } }
    }

    func contains(_ bundleId: String, in id: UUID) -> Bool {
        folder(id)?.apps.contains { $0.bundleId == bundleId } ?? false
    }

    /// Adds the app, or removes it if the folder already has it.
    func toggle(_ app: AppRef, in id: UUID) {
        modify(id) { folder in
            if let i = folder.apps.firstIndex(where: { $0.bundleId == app.bundleId }) {
                folder.apps.remove(at: i)
            } else if folder.apps.count < Folder.maxApps {
                folder.apps.append(app)
            }
        }
    }

    /// Gives the widget a copy of every icon it doesn't have yet, then redraws it.
    func shareIcons() async {
        if await IconCache.shareIcons(for: library.folders.flatMap(\.apps)) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func change(_ edit: (inout Library) -> Void) {
        var updated = library
        edit(&updated)
        library = updated
        do {
            try Store.save(updated)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            errorMessage = "Couldn't save: \(error.localizedDescription)"
        }
        Task { await shareIcons() }
    }
}
