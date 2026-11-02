import SwiftUI

/// An app's icon: the loaded image, or a drawn symbol or letter. Dark draws it the way iOS
/// dark icons look: the light background turns near-black, the logo keeps its full colour.
struct AppIconView: View {
    let app: AppRef
    let image: UIImage?
    let size: CGFloat
    var dark = false

    var body: some View {
        content
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
    }

    @ViewBuilder
    private var content: some View {
        if let image {
            if dark {
                Image(uiImage: DarkIcon.make(image)).resizable()
            } else {
                Image(uiImage: image).resizable()
            }
        } else {
            switch app.icon {
            case .symbol(let name, let hex):
                tile(hex).overlay(
                    Image(systemName: name).font(.system(size: size * 0.45)).foregroundStyle(glyph(hex)))
            case .letter(let hex):
                tile(hex).overlay(
                    Text(String(app.name.prefix(1)).uppercased())
                        .font(.system(size: size * 0.5, weight: .semibold))
                        .foregroundStyle(glyph(hex)))
            case .artwork, .system, .photo:
                Color.gray.opacity(0.3)
            }
        }
    }

    private func tile(_ hex: String) -> Color { dark ? Color(hex: "#1C1C1E") : Color(hex: hex) }
    private func glyph(_ hex: String) -> Color { dark ? Color(hex: hex) : .white }
}

/// Dark versions of icon pictures. Flood-fills the light area connected to the icon's edge (its
/// background) and paints it the iOS dark tile colour, so a white glyph inside a coloured icon
/// stays white and the logo is never dimmed.
enum DarkIcon {
    private static let cache = NSCache<UIImage, UIImage>()
    private static let tile: (r: Double, g: Double, b: Double) = (28, 28, 30)

    static func make(_ image: UIImage) -> UIImage {
        if let done = cache.object(forKey: image) { return done }
        let result = darken(image) ?? image
        cache.setObject(result, forKey: image)
        return result
    }

    private static func darken(_ image: UIImage) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let w = cg.width, h = cg.height
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let px = ctx.data?.bindMemory(to: UInt8.self, capacity: w * h * 4) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        func light(_ i: Int) -> Int { Int(min(px[i * 4], px[i * 4 + 1], px[i * 4 + 2])) }
        let threshold = 184 // all three channels this bright: white or light grey

        // flood fill from every edge pixel through light pixels
        var filled = [Bool](repeating: false, count: w * h)
        var stack: [Int] = []
        for x in 0..<w { stack += [x, (h - 1) * w + x] }
        for y in 0..<h { stack += [y * w, y * w + w - 1] }
        while let i = stack.popLast() {
            guard !filled[i], light(i) >= threshold else { continue }
            filled[i] = true
            let x = i % w, y = i / w
            if x > 0 { stack.append(i - 1) }
            if x < w - 1 { stack.append(i + 1) }
            if y > 0 { stack.append(i - w) }
            if y < h - 1 { stack.append(i + w) }
        }

        for i in 0..<(w * h) {
            var amount = 0.0
            if filled[i] {
                amount = 1
            } else {
                // soften the anti-aliased edge where the background meets the logo
                let x = i % w, y = i / w
                let nearFill = (x > 0 && filled[i - 1]) || (x < w - 1 && filled[i + 1])
                    || (y > 0 && filled[i - w]) || (y < h - 1 && filled[i + w])
                if nearFill { amount = min(1, max(0, Double(light(i) - 80) / Double(threshold - 80))) }
            }
            guard amount > 0 else { continue }
            let alpha = Double(px[i * 4 + 3]) / 255
            let target = [tile.r, tile.g, tile.b]
            for c in 0..<3 {
                let old = Double(px[i * 4 + c])
                px[i * 4 + c] = UInt8(old * (1 - amount) + target[c] * alpha * amount)
            }
        }
        return ctx.makeImage().map { UIImage(cgImage: $0) }
    }
}

/// A folder's background in a given shape. Auto colour in dark mode copies the iOS App Library
/// folders: near-black, lit from the top, with a thin glass edge.
struct FolderBackground<S: InsettableShape>: View {
    let folder: Folder
    let shape: S
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if let id = folder.backgroundPhoto, let photo = IconCache.photo(id) {
            Color.clear
                .overlay(Image(uiImage: photo).resizable().scaledToFill())
                .overlay(Color.black.opacity(folder.backgroundDim ?? Folder.defaultBackgroundDim))
                .clipShape(shape)
        } else if folder.isAutoColor && scheme == .dark {
            shape
                .fill(LinearGradient(colors: [Color(hex: "#232326"), Color(hex: "#111113")],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(shape.strokeBorder(LinearGradient(colors: [.white.opacity(0.22), .white.opacity(0.04)],
                                                           startPoint: .top, endPoint: .bottom),
                                            lineWidth: 1))
        } else {
            shape.fill(folder.background(scheme).gradient)
        }
    }
}

extension Folder {
    var isAutoColor: Bool { colorHex == Palette.auto }

    func background(_ scheme: ColorScheme) -> Color {
        guard isAutoColor else { return Color(hex: colorHex) }
        return scheme == .dark ? Color(hex: "#2C2C2E") : Color(hex: "#E5E5EA")
    }

    /// The folder name on the widget: dark text only on the light Auto background.
    func nameColor(_ scheme: ColorScheme) -> Color {
        isAutoColor && scheme == .light && backgroundPhoto == nil ? .black : .white
    }

    func usesDarkIcons(_ scheme: ColorScheme) -> Bool {
        switch iconStyle ?? .original {
        case .original: return false
        case .dark: return true
        case .auto: return scheme == .dark
        }
    }
}
