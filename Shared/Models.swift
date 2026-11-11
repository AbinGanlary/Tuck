import Foundation

struct Library: Codable {
    var folders: [Folder] = []
    var linkLaunch: LinkLaunch?     // how the widget opens LiveContainer links; nil = the default

    var effectiveLinkLaunch: LinkLaunch { linkLaunch ?? .bounce }
}

/// Ways a widget tap can open a link. Bounce is the one proven on the phone (row C of the launch
/// test); the other two are there to try with LiveContainer links.
enum LinkLaunch: String, Codable, CaseIterable {
    case bounce = "Through Tuck"    // Link to tuck://open, Tuck opens the link (brief flash)
    case direct = "Direct"          // intent in the widget process, private LSApplicationWorkspace openURL
    case openURLIntent = "OpenURLIntent"
}

struct Folder: Codable, Identifiable, Hashable {
    static let maxApps = 49 // 7 × 7, the large widget

    var id: UUID
    var name: String
    var colorHex: String
    var showName: Bool
    var apps: [AppRef]
    // Optional so folders saved before these existed still decode; nil means the default.
    var iconStyle: IconStyle?
    var iconScale: Double?          // share of the largest icon that fits the grid
    var iconSpacing: Double?        // points between icons (the edge gap follows it)
    var widgetShape: WidgetShape?   // the one size the widget gallery offers; nil = Auto (by app count)
    var backgroundPhoto: UUID?      // JPEG "photo-<id>" in SharedBlobs, drawn instead of the colour
    var backgroundDim: Double?      // black over the photo so icons stand out

    static let defaultIconScale = 1.0
    static let defaultIconSpacing = 8.0
    static let defaultBackgroundDim = 0.25

    static func new() -> Folder {
        Folder(id: UUID(), name: "", colorHex: Palette.folderColors[0], showName: false, apps: [],
               iconStyle: .original)
    }

    /// The chosen widget size, or the smallest one that fits every app.
    var effectiveShape: WidgetShape { widgetShape ?? .fitting(apps.count) }
}

enum IconStyle: String, Codable, CaseIterable {
    case original = "Original"
    case dark = "Dark"
    case auto = "Auto" // dark when the phone is in dark mode
}

struct AppRef: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var bundleId: String            // empty for a LiveContainer app
    var icon: IconSource
    // An app inside LiveContainer: iOS doesn't see it as installed, so it opens by this launch link
    // instead of by bundle ID. Optional so items saved before it existed still decode.
    var launchURL: URL?

    var inLiveContainer: Bool { launchURL != nil }
    /// What makes two items the same app: the launch link, else the bundle ID.
    var key: String { launchURL?.absoluteString ?? bundleId }
}

enum IconSource: Codable, Hashable {
    case artwork(URL)                           // App Store artwork, or any image URL
    case photo(UUID)                            // picked from Photos; JPEG "photo-<id>" in SharedBlobs
    case system                                 // Home Screen icon via private API (Apple's apps)
    case symbol(name: String, colorHex: String)
    case letter(colorHex: String)
}
