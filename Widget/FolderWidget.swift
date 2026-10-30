import AppIntents
import SwiftUI
import WidgetKit

// Each widget kind shows one position in the app's folder list ("Folder 1" = the first folder).
// Per-widget configuration (AppIntentConfiguration) never loads under the user's signing: test
// widgets showed the picker lists folders but a configurable widget's timeline never runs, while
// plain StaticConfiguration widgets do.

// MARK: - Timeline

struct FolderEntry: TimelineEntry {
    let date: Date
    let slot: Int
    let folder: Folder?
    let icons: [UUID: UIImage]
}

struct FolderProvider: TimelineProvider {
    let slot: Int

    func placeholder(in context: Context) -> FolderEntry {
        FolderEntry(date: Date(), slot: slot, folder: nil, icons: [:])
    }

    func getSnapshot(in context: Context, completion: @escaping (FolderEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FolderEntry>) -> Void) {
        // the app reloads widgets after every change, so no scheduled refresh
        completion(Timeline(entries: [entry()], policy: .never))
    }

    private func entry() -> FolderEntry {
        let folders = Store.load().folders
        guard folders.indices.contains(slot) else {
            WidgetLog.write("widget \(slot + 1): no folder \(slot + 1) (\(folders.count) folders)")
            return FolderEntry(date: Date(), slot: slot, folder: nil, icons: [:])
        }
        let folder = folders[slot]
        var icons: [UUID: UIImage] = [:]
        for app in folder.apps {
            icons[app.id] = IconCache.sharedImage(for: app)
        }
        WidgetLog.write("widget \(slot + 1): \(folder.name), \(icons.count) of \(folder.apps.count) icons")
        return FolderEntry(date: Date(), slot: slot, folder: folder, icons: icons)
    }
}

// MARK: - View

struct FolderWidgetView: View {
    let entry: FolderEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme

    private var shape: WidgetShape {
        switch family {
        case .systemSmall: return .small
        case .systemLarge: return .large
        default: return .medium
        }
    }

    var body: some View {
        Group {
            if let folder = entry.folder {
                FolderLayout(folder: folder, shape: shape) { index, icon in
                    slot(folder, index: index, icon: icon)
                }
            } else {
                Text("Make folder \(entry.slot + 1) in Tuck").font(.caption).multilineTextAlignment(.center)
            }
        }
        .containerBackground(for: .widget) {
            if let folder = entry.folder {
                FolderBackground(folder: folder, shape: ContainerRelativeShape())
            } else {
                Color.gray.opacity(0.2)
            }
        }
    }

    @ViewBuilder
    private func slot(_ folder: Folder, index: Int, icon: CGFloat) -> some View {
        if index < folder.apps.count {
            let app = folder.apps[index]
            Button(intent: OpenBundleIntent(bundleId: app.bundleId)) {
                AppIconView(app: app, image: entry.icons[app.id], size: icon, dark: folder.usesDarkIcons(scheme))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            Color.clear
        }
    }
}

/// The gallery offers each folder only in the size picked in the app, and hides slots with no
/// folder. iOS caches this list, so changes can take a gallery reopen or a restart to show.
/// Title and description go in as String values: a literal with interpolation becomes a
/// LocalizedStringKey with arguments, and WidgetKit traps on that (it once hid Tuck from the gallery).
private func folderWidget(slot: Int) -> some WidgetConfiguration {
    let folders = Store.load().folders
    let folder = folders.indices.contains(slot) ? folders[slot] : nil
    let title: String = "Folder \(slot + 1)" + (folder.map { " · \($0.name)" } ?? "")
    let description: String = "Shows folder \(slot + 1) in Tuck. Change the order and size in the app."
    let families: [WidgetFamily]
    switch folder?.effectiveShape {
    case .small: families = [.systemSmall]
    case .medium: families = [.systemMedium]
    case .large: families = [.systemLarge]
    case nil: families = [] // no folder in this slot: hide it
    }
    return StaticConfiguration(kind: "TuckFolder\(slot + 1)", provider: FolderProvider(slot: slot)) { entry in
        FolderWidgetView(entry: entry)
    }
    .configurationDisplayName(title)
    .description(description)
    .supportedFamilies(families)
    .contentMarginsDisabled() // FolderLayout draws its own edge gap
}

struct FolderWidget1: Widget { var body: some WidgetConfiguration { folderWidget(slot: 0) } }
struct FolderWidget2: Widget { var body: some WidgetConfiguration { folderWidget(slot: 1) } }
struct FolderWidget3: Widget { var body: some WidgetConfiguration { folderWidget(slot: 2) } }
struct FolderWidget4: Widget { var body: some WidgetConfiguration { folderWidget(slot: 3) } }
struct FolderWidget5: Widget { var body: some WidgetConfiguration { folderWidget(slot: 4) } }
struct FolderWidget6: Widget { var body: some WidgetConfiguration { folderWidget(slot: 5) } }

@main
struct TuckWidgetBundle: WidgetBundle {
    var body: some Widget {
        FolderWidget1()
        FolderWidget2()
        FolderWidget3()
        FolderWidget4()
        FolderWidget5()
        FolderWidget6()
    }
}
