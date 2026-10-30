import Foundation
import SwiftUI

enum Shared {
    static let appGroup = "group.com.abin.tuck"

    /// nil when signing didn't grant the App Group (the user's certificate doesn't).
    static var container: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }
}

enum Palette {
    /// Folder colour that follows the phone: light grey in light mode, dark grey in dark mode.
    static let auto = "auto"

    static let folderColors = [
        "#115253", "#FF7A59", "#FFC145", "#5BC0EB",
        "#34C759", "#3E63DD", "#E5484D", "#3A3A3C",
    ]
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
        self.init(red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255)
    }
}
