import SwiftUI

/// The three widget sizes and their grids.
enum WidgetShape: String, Codable, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    var columns: Int { self == .small ? 3 : 7 }
    var rows: Int { self == .large ? 7 : 3 }
    var capacity: Int { columns * rows }

    /// Auto size: the smallest widget that holds this many apps.
    static func fitting(_ count: Int) -> WidgetShape {
        count <= small.capacity ? .small : count <= medium.capacity ? .medium : .large
    }
}

/// A folder widget's content: optional name, then a fixed grid of cells filling the widget edge to
/// edge (the widget's own margins are off). The gap between icons comes from the spacing slider and
/// the edge gap follows it; icons take the largest size that fits, times the size slider. The
/// widget and the app's preview both draw through this, so the preview matches the Home Screen.
struct FolderLayout<Cell: View>: View {
    let folder: Folder
    let shape: WidgetShape
    @ViewBuilder let cell: (_ index: Int, _ iconSize: CGFloat) -> Cell
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let gap = CGFloat(folder.iconSpacing ?? Folder.defaultIconSpacing)
        let edge = gap + 6

        VStack(spacing: 0) {
            if folder.showName {
                Text(folder.name)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(folder.nameColor(scheme))
                    .lineLimit(1)
                    .padding(.top, edge)
            }
            GeometryReader { geo in
                let columns = CGFloat(shape.columns)
                let rows = CGFloat(shape.rows)
                let widest = (geo.size.width - 2 * edge - gap * (columns - 1)) / columns
                let tallest = (geo.size.height - 2 * edge - gap * (rows - 1)) / rows
                let icon = max(4, min(widest, tallest) * (folder.iconScale ?? Folder.defaultIconScale))
                VStack(spacing: gap) {
                    ForEach(0..<shape.rows, id: \.self) { row in
                        HStack(spacing: gap) {
                            ForEach(0..<shape.columns, id: \.self) { column in
                                cell(row * shape.columns + column, icon)
                                    .frame(width: icon, height: icon)
                            }
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}
