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

    /// Fallback routes that open an app through Tuck: tuck://bundle?id=<bundleId> and
    /// tuck://open?id=<item id> (how the widget opens LiveContainer links by default; older widgets
    /// may still send ?url=<link>).
    private func handle(_ url: URL) {
        let value = { (name: String) in
            URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == name }?.value
        }
        switch url.host {
        case "bundle":
            if let id = value("id") { PrivateApps.openBundle(id) }
        case "open":
            let item = value("id").flatMap(UUID.init(uuidString:)).flatMap { id in
                model.library.folders.flatMap(\.apps).first { $0.id == id }
            }
            guard let link = item?.launchURL ?? value("url").flatMap(URL.init(string:)) else {
                WidgetLog.write("through Tuck: no link for \(url.absoluteString)")
                return
            }
            Task { await openWhenActive(link) }
        default:
            break
        }
    }

    /// Opening another app while Tuck is still coming to the front can quietly fail, so wait
    /// until it's active (up to 2 s) and try once more if the first open doesn't take.
    private func openWhenActive(_ link: URL) async {
        for _ in 0..<20 where UIApplication.shared.applicationState != .active {
            try? await Task.sleep(for: .milliseconds(100))
        }
        var opened = await UIApplication.shared.open(link)
        if !opened {
            try? await Task.sleep(for: .milliseconds(500))
            opened = await UIApplication.shared.open(link)
        }
        WidgetLog.write("through Tuck \(link.scheme ?? "?"): \(opened ? "opened" : "FAILED")")
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

    /// Whether the folder has this app (`AppRef.key`: the bundle ID, or a LiveContainer launch link).
    func contains(_ key: String, in id: UUID) -> Bool {
        folder(id)?.apps.contains { $0.key == key } ?? false
    }

    func setLinkLaunch(_ launch: LinkLaunch) {
        change { $0.linkLaunch = launch }
    }

    /// Adds the app, or removes it if the folder already has it.
    func toggle(_ app: AppRef, in id: UUID) {
        modify(id) { folder in
            if let i = folder.apps.firstIndex(where: { $0.key == app.key }) {
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
