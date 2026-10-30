import Foundation

struct Library: Codable {
    var folders: [Folder] = []
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

    static let defaultIconScale = 1.0
    static let defaultIconSpacing = 8.0

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
    var bundleId: String
    var icon: IconSource
}

enum IconSource: Codable, Hashable {
    case artwork(URL)                           // App Store artwork, or any image URL
    case photo(UUID)                            // picked from Photos; JPEG in keychain "photo-<id>"
    case system                                 // Home Screen icon via private API (Apple's apps)
    case symbol(name: String, colorHex: String)
    case letter(colorHex: String)
}
