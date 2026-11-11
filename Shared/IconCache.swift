import Security
import UIKit

/// Icon images. The app downloads App Store artwork, keeps a file cache for its own screens and
/// shares a small JPEG of each icon with the widget through SharedBlobs. The widget never touches
/// the network: widgets get little memory and time, and downloading there left it stuck loading.
enum IconCache {
    // pixels: sharp up to a small widget's ~64 pt icons at 3×, yet 49 of them (plus dark copies)
    // stay well inside the widget's memory limit
    private static let side: CGFloat = 192

    private static var dir: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("icons-192", isDirectory: true) // new name: older 120 px copies are ignored
    }

    /// For the app's screens; downloads when needed. nil means draw the symbol or letter instead.
    static func image(for app: AppRef) async -> UIImage? {
        switch app.icon {
        case .artwork(let url): return await fetch(url)
        case .photo(let id): return photo(id)
        case .system: return PrivateApps.icon(app.bundleId)
        case .symbol, .letter: return nil
        }
    }

    /// For the widget: only the copies the app has already shared.
    static func sharedImage(for app: AppRef) -> UIImage? {
        switch app.icon {
        case .artwork(let url): return SharedBlobs.read(account: sharedAccount(url)).flatMap(UIImage.init(data:))
        case .photo(let id): return photo(id)
        case .system: return PrivateApps.icon(app.bundleId)
        case .symbol, .letter: return nil
        }
    }

    // MARK: Photos: icons (square 180 px) and widget backgrounds (up to 900 px), JPEGs in SharedBlobs

    private static let photos = NSCache<NSUUID, UIImage>() // a photo never changes under its id

    static func photo(_ id: UUID) -> UIImage? {
        if let cached = photos.object(forKey: id as NSUUID) { return cached }
        guard let image = SharedBlobs.read(account: "photo-\(id.uuidString)").flatMap(UIImage.init(data:))
        else { return nil }
        photos.setObject(image, forKey: id as NSUUID)
        return image
    }

    /// Shrinks the picked picture so its long side is at most 900 px (a large widget is about
    /// 1100 × 1150 px, and the widget has little memory) and saves it. nil if it isn't an image.
    static func saveBackground(_ data: Data) -> UUID? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, 900 / max(image.size.width, image.size.height))
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let jpeg = UIGraphicsImageRenderer(size: size, format: format).jpegData(withCompressionQuality: 0.75) { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        let id = UUID()
        return SharedBlobs.write(jpeg, account: "photo-\(id.uuidString)") == errSecSuccess ? id : nil
    }

    /// Crops the picked picture to its centre square, shrinks it and saves it. nil if it isn't an image.
    static func savePhoto(_ data: Data) -> UUID? {
        guard let image = UIImage(data: data) else { return nil }
        let crop = min(image.size.width, image.size.height)
        let scale = 180 / crop
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let jpeg = UIGraphicsImageRenderer(size: CGSize(width: 180, height: 180), format: format)
            .jpegData(withCompressionQuality: 0.85) { _ in
                image.draw(in: CGRect(x: -(image.size.width - crop) / 2 * scale,
                                      y: -(image.size.height - crop) / 2 * scale,
                                      width: image.size.width * scale, height: image.size.height * scale))
            }
        let id = UUID()
        return SharedBlobs.write(jpeg, account: "photo-\(id.uuidString)") == errSecSuccess ? id : nil
    }

    /// Makes sure every artwork icon has a shared copy. true when it added any.
    static func shareIcons(for apps: [AppRef]) async -> Bool {
        var added = false
        for app in apps {
            guard case .artwork(let url) = app.icon else { continue }
            let account = sharedAccount(url)
            guard SharedBlobs.read(account: account) == nil,
                  let jpeg = await fetch(url)?.jpegData(compressionQuality: 0.85) else { continue }
            if SharedBlobs.write(jpeg, account: account) == errSecSuccess { added = true }
        }
        return added
    }

    static func fetch(_ url: URL) async -> UIImage? {
        let file = dir.appendingPathComponent(key(url) + ".png")
        if let cached = UIImage(contentsOfFile: file.path) { return cached }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let full = UIImage(data: data) else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let small = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            full.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? small.pngData()?.write(to: file, options: .atomic)
        return small
    }

    private static func sharedAccount(_ url: URL) -> String { "icon192-" + key(url) }

    /// Stable name for a URL (FNV-1a; String.hashValue changes between launches).
    private static func key(_ url: URL) -> String {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in url.absoluteString.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100_0000_01b3
        }
        return String(hash, radix: 16)
    }
}

/// The widget's last few steps, readable in the app's About screen.
enum WidgetLog {
    private static let account = "widget-log"

    @discardableResult
    static func write(_ line: String) -> OSStatus {
        let stamped = "\(Date().formatted(date: .omitted, time: .standard))  \(line)"
        let lines = [stamped] + read().split(separator: "\n").prefix(7).map(String.init)
        return SharedBlobs.write(Data(lines.joined(separator: "\n").utf8), account: account)
    }

    static func read() -> String {
        SharedBlobs.read(account: account).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }
}
