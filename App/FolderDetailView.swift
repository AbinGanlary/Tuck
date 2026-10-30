import SwiftUI
import UniformTypeIdentifiers

/// S03: the folder drawn exactly like its widget (same layout code, Home Screen size). Drag icons
/// to arrange them, tap one to open or remove it, and set the icon size.
struct FolderDetailView: View {
    @EnvironmentObject private var model: LibraryModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    let folderID: UUID
    @State private var sizeChoice: WidgetShape?   // nil = Auto
    private var size: WidgetShape { sizeChoice ?? .fitting(apps.count) }
    @State private var iconScale = Folder.defaultIconScale
    @State private var iconSpacing = Folder.defaultIconSpacing
    @State private var apps: [AppRef] = []      // local order while dragging; saved on drop
    @State private var dragging: AppRef?
    @State private var selected: AppRef?
    @State private var adding = false
    @State private var editing: Folder?
    @State private var confirmDelete = false
    @State private var iconEditing: AppRef?

    private var widgetNumber: Int {
        (model.library.folders.firstIndex { $0.id == folderID } ?? 0) + 1
    }

    var body: some View {
        ScrollView {
            if let folder = model.folder(folderID) {
                VStack(spacing: 20) {
                    // the desk mat: every setting that shapes the widget, in one stitched panel
                    VStack(spacing: 16) {
                        Picker("Widget size", selection: Binding(get: { sizeChoice }, set: { new in
                            sizeChoice = new
                            model.modify(folderID) { $0.widgetShape = new }
                        })) {
                            Text("Auto").tag(WidgetShape?.none)
                            ForEach(WidgetShape.allCases, id: \.self) { Text($0.rawValue).tag(Optional($0)) }
                        }
                        .pickerStyle(.segmented)

                        sliderRow("Icon size", value: $iconScale, range: 0.5...1.0,
                                  small: "app.fill", large: "app.fill") { scale in
                            model.modify(folderID) { $0.iconScale = scale }
                        }
                        sliderRow("Spacing", value: $iconSpacing, range: 0...20,
                                  small: "square.grid.3x3.fill", large: "square.grid.3x3") { spacing in
                            model.modify(folderID) { $0.iconSpacing = spacing }
                        }
                    }
                    .padding(18)
                    .background(StitchedPanel())

                    preview(folder)
                        .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 8)
                        .padding(.vertical, 6)
                    overflow(folder)

                    Text(caption(folder))
                        .font(.footnote)
                        .foregroundStyle(Theme.embossSoft)
                        .multilineTextAlignment(.center)

                    Button("Delete folder", role: .destructive) { confirmDelete = true }
                        .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(Theme.ground.ignoresSafeArea())
        // a drop that misses every icon still ends the drag and saves the order
        .onDrop(of: [.text], delegate: EndDragDelegate(dragging: $dragging, commit: commit))
        .navigationTitle(model.folder(folderID)?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let folder = model.folder(folderID)
            apps = folder?.apps ?? []
            iconScale = folder?.iconScale ?? Folder.defaultIconScale
            iconSpacing = folder?.iconSpacing ?? Folder.defaultIconSpacing
            sizeChoice = folder?.widgetShape
        }
        .onChange(of: model.folder(folderID)?.apps) { _, new in
            if dragging == nil { apps = new ?? [] }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { editing = model.folder(folderID) } label: { Image(systemName: "paintpalette") }
                Button { adding = true } label: { Image(systemName: "plus") }
                    .disabled(apps.count >= Folder.maxApps)
            }
        }
        .sheet(isPresented: $adding) { AddAppView(folderID: folderID) }
        .sheet(item: $editing) { FolderEditor(folder: $0) }
        .sheet(item: $iconEditing) { IconEditor(folderID: folderID, app: $0) }
        .confirmationDialog(selected?.name ?? "", isPresented: Binding(
            get: { selected != nil }, set: { if !$0 { selected = nil } }), titleVisibility: .visible
        ) {
            if let app = selected {
                Button("Open") { PrivateApps.openBundle(app.bundleId) }
                Button("Change icon") { iconEditing = app }
                Button("Remove from folder", role: .destructive) {
                    model.modify(folderID) { $0.apps.removeAll { $0.id == app.id } }
                }
            }
        }
        .confirmationDialog("Delete this folder?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete folder", role: .destructive) {
                model.delete(folderID)
                dismiss()
            }
        }
    }

    /// Home Screen widget sizes, scaled from the iPhone 16 Pro (402 pt wide: 170, 364 × 170, 364 × 382).
    private var widgetFrame: CGSize {
        let width = UIScreen.main.bounds.width
        switch size {
        case .small: return CGSize(width: width * 0.423, height: width * 0.423)
        case .medium: return CGSize(width: width * 0.905, height: width * 0.423)
        case .large: return CGSize(width: width * 0.905, height: width * 0.950)
        }
    }

    private func preview(_ folder: Folder) -> some View {
        var shown = folder
        shown.iconScale = iconScale     // follow the sliders live
        shown.iconSpacing = iconSpacing
        let dark = folder.usesDarkIcons(scheme)

        return FolderLayout(folder: shown, shape: size) { index, icon in
            if index < apps.count {
                draggableIcon(apps[index], size: icon, dark: dark)
            } else {
                RoundedRectangle(cornerRadius: icon * 0.225, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: icon, height: icon)
            }
        }
        .frame(width: widgetFrame.width, height: widgetFrame.height)
        .background(FolderBackground(folder: folder, shape: RoundedRectangle(cornerRadius: 22, style: .continuous)))
    }

    /// A slider that redraws the preview while moving and saves (refreshing the widget) on release.
    private func sliderRow(_ label: String, value: Binding<Double>, range: ClosedRange<Double>,
                           small: String, large: String, save: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.emboss)
            HStack(spacing: 12) {
                Image(systemName: small).font(.caption)
                Slider(value: value, in: range) { editing in
                    if !editing { save(value.wrappedValue) }
                }
                .accessibilityLabel(label)
                Image(systemName: large).font(.title3)
            }
            .foregroundStyle(Theme.embossSoft)
        }
    }

    /// Apps past this size's capacity, so they can still be dragged into the widget.
    @ViewBuilder
    private func overflow(_ folder: Folder) -> some View {
        if apps.count > size.capacity {
            VStack(alignment: .leading, spacing: 8) {
                Text("Not shown in a \(size.rawValue.lowercased()) widget. Drag one into the grid to swap it in.")
                    .font(.footnote)
                    .foregroundStyle(Theme.embossSoft)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(apps[size.capacity...]) { app in
                        draggableIcon(app, size: 40, dark: folder.usesDarkIcons(scheme))
                    }
                }
            }
        }
    }

    private func draggableIcon(_ app: AppRef, size: CGFloat, dark: Bool) -> some View {
        LoadedIcon(app: app, size: size, dark: dark)
            .opacity(dragging?.id == app.id ? 0.4 : 1)
            .onTapGesture { selected = app }
            .onDrag {
                dragging = app
                return NSItemProvider(object: app.id.uuidString as NSString)
            }
            .onDrop(of: [.text], delegate: ReorderDelegate(target: app, apps: $apps,
                                                           dragging: $dragging, commit: commit))
    }

    private func caption(_ folder: Folder) -> String {
        if apps.isEmpty { return "No apps yet. Tap + to add some." }
        let auto = sizeChoice == nil ? " Auto chose \(size.rawValue.lowercased()) for \(apps.count) apps." : ""
        return "Drag to arrange. Tap an icon to open, change or remove it.\n"
            + "In Add Widget this is “Folder \(widgetNumber)”, \(size.rawValue.lowercased()) only.\(auto)"
    }

    private func commit() {
        let order = apps
        model.modify(folderID) { $0.apps = order }
    }
}

/// Moves the dragged icon into the hovered icon's place as the finger passes over it.
private struct ReorderDelegate: DropDelegate {
    let target: AppRef
    @Binding var apps: [AppRef]
    @Binding var dragging: AppRef?
    let commit: () -> Void

    func dropEntered(info: DropInfo) {
        guard let dragging, dragging.id != target.id,
              let from = apps.firstIndex(where: { $0.id == dragging.id }),
              let to = apps.firstIndex(where: { $0.id == target.id }) else { return }
        withAnimation(.snappy) {
            apps.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        commit()
        return true
    }
}

private struct EndDragDelegate: DropDelegate {
    @Binding var dragging: AppRef?
    let commit: () -> Void

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        commit()
        return true
    }
}
