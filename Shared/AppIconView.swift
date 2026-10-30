import SwiftUI

/// An app's icon: the loaded image, or a drawn symbol or letter. Dark draws it the way iOS
/// dark icons look: a near-black tile, the picture dimmed, symbols and letters in colour.
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
                Color.black.overlay(Image(uiImage: image).resizable().saturation(0.85).opacity(0.75))
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

/// A folder's background in a given shape. Auto colour in dark mode copies the iOS App Library
/// folders: near-black, lit from the top, with a thin glass edge.
struct FolderBackground<S: InsettableShape>: View {
    let folder: Folder
    let shape: S
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if folder.isAutoColor && scheme == .dark {
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
        isAutoColor && scheme == .light ? .black : .white
    }

    func usesDarkIcons(_ scheme: ColorScheme) -> Bool {
        switch iconStyle ?? .original {
        case .original: return false
        case .dark: return true
        case .auto: return scheme == .dark
        }
    }
}
