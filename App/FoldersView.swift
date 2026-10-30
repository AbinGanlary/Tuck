import SwiftUI
import WidgetKit

/// S01: every folder as a leather pocket with its apps tucked in. S02 (FolderEditor) creates and edits them.
struct FoldersView: View {
    @EnvironmentObject private var model: LibraryModel
    @State private var editing: Folder?
    @State private var showInfo = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if model.library.folders.isEmpty {
                    emptyPocket
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 18) {
                    ForEach(Array(model.library.folders.enumerated()), id: \.element.id) { index, folder in
                        NavigationLink(value: folder.id) {
                            FolderCard(folder: folder, position: index)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Move earlier", systemImage: "arrow.left") { model.move(folder.id, by: -1) }
                                .disabled(index == 0)
                            Button("Move later", systemImage: "arrow.right") { model.move(folder.id, by: 1) }
                                .disabled(index == model.library.folders.count - 1)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Theme.ground.ignoresSafeArea())
            .navigationTitle("Folders")
            .navigationDestination(for: UUID.self) { FolderDetailView(folderID: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showInfo = true } label: { Image(systemName: "info.circle") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editing = Folder.new() } label: { Image(systemName: "plus") }
                }
            }
            .sheet(item: $editing) { FolderEditor(folder: $0) }
            .sheet(isPresented: $showInfo) { DiagnosticsView() }
            .alert("Something went wrong", isPresented: Binding(
                get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }

    private var emptyPocket: some View {
        VStack(spacing: 10) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Theme.cognac)
            Text("No folders yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.emboss)
            Text("Tap + to make one, then add it to your Home Screen as a Tuck widget.")
                .font(.subheadline)
                .foregroundStyle(Theme.embossSoft)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(StitchedPanel())
        .padding(.horizontal, 16)
        .padding(.top, 40)
    }
}

/// A folder as a pocket: its colour lines the slot, its first apps peek out above the stitched
/// front, and the front carries the name and the widget number that shows it.
struct FolderCard: View {
    static let widgetCount = 6 // Folder 1 … Folder 6 in the widget gallery

    let folder: Folder
    let position: Int
    @Environment(\.colorScheme) private var scheme

    private let iconSize: CGFloat = 44
    private let frontTop: CGFloat = 54 // the front covers the bottom third of the peeking icons

    var body: some View {
        ZStack(alignment: .top) {
            StitchedPanel(fill: Theme.pocket, cornerRadius: 24)

            UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16, style: .continuous)
                .fill(folder.background(scheme).opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .frame(height: frontTop + 20)

            HStack(spacing: 6) {
                ForEach(folder.apps.prefix(3)) { app in
                    LoadedIcon(app: app, size: iconSize, dark: folder.usesDarkIcons(scheme))
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                }
                if folder.apps.isEmpty {
                    Text("Empty").font(.caption).foregroundStyle(folder.nameColor(scheme).opacity(0.7))
                        .frame(height: iconSize)
                }
            }
            .padding(.top, 22)

            front
                .padding(.top, frontTop)
        }
        .frame(height: 140) // front is just tall enough for the name, count and numeral
        .contentShape(Rectangle())
    }

    private var front: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(folder.name)
                    .font(.headline)
                    .foregroundStyle(Theme.emboss)
                    .shadow(color: .black.opacity(0.35), radius: 0, x: 0, y: -0.5) // pressed into the leather
                    .lineLimit(1)
                Text(position < Self.widgetCount ? "\(folder.apps.count) apps" : "No widget slot")
                    .font(.caption)
                    .foregroundStyle(Theme.embossSoft)
            }
            Spacer(minLength: 0)
            Text(position < Self.widgetCount ? "\(position + 1)" : "–")
                .font(.system(.largeTitle, design: .rounded).weight(.light))
                .foregroundStyle(Theme.embossSoft)
                .accessibilityLabel(position < Self.widgetCount ? "Widget \(position + 1)" : "No widget")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(StitchedPanel(fill: Theme.pocketFront, cornerRadius: 20))
    }
}

struct FolderEditor: View {
    @EnvironmentObject private var model: LibraryModel
    @Environment(\.dismiss) private var dismiss
    @State private var folder: Folder

    init(folder: Folder) {
        _folder = State(initialValue: folder)
    }

    private var isNew: Bool { model.folder(folder.id) == nil }

    var body: some View {
        NavigationStack {
            Form {
                Group {
                    Section {
                        TextField("Folder name", text: $folder.name)
                    }
                    Section {
                        ColorSwatches(selection: $folder.colorHex, includeAuto: true)
                    } header: {
                        Text("Colour")
                    } footer: {
                        Text("The first swatch is Auto: light grey in light mode, dark grey in dark mode.")
                    }
                    Section {
                        Picker("Icons", selection: Binding(get: { folder.iconStyle ?? .original },
                                                           set: { folder.iconStyle = $0 })) {
                            ForEach(IconStyle.allCases, id: \.self) { Text($0.rawValue) }
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Icon style")
                    } footer: {
                        Text("Auto uses dark icons when your iPhone is in dark mode.")
                    }
                    Section {
                        Toggle("Show name on widget", isOn: $folder.showName)
                    }
                }
                .listRowBackground(Theme.pocket)
            }
            .walletList()
            .navigationTitle(isNew ? "New folder" : "Edit folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        folder.name = folder.name.trimmingCharacters(in: .whitespaces)
                        model.save(folder)
                        dismiss()
                    }
                    .disabled(folder.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct ColorSwatches: View {
    @Binding var selection: String
    var includeAuto = false // folders only: icon colours can't follow the phone

    private var choices: [String] { (includeAuto ? [Palette.auto] : []) + Palette.folderColors }

    var body: some View {
        HStack {
            ForEach(choices, id: \.self) { hex in
                Circle()
                    .fill(hex == Palette.auto
                          ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "#E5E5EA"), Color(hex: "#2C2C2E")],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                          : AnyShapeStyle(Color(hex: hex)))
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color.primary, lineWidth: selection == hex ? 3 : 0).padding(-4))
                    .onTapGesture { selection = hex }
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 6)
    }
}

/// Loads an app's icon in the background and draws it.
struct LoadedIcon: View {
    let app: AppRef
    let size: CGFloat
    var dark = false
    @State private var image: UIImage?

    var body: some View {
        AppIconView(app: app, image: image, size: size, dark: dark)
            .task(id: app.icon) { image = await IconCache.image(for: app) }
    }
}

struct DiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var widgetLog = WidgetLog.read()
    @AppStorage(AppStore.countryKey) private var storeCountry = ""

    var body: some View {
        NavigationStack {
            Form {
                Group {
                    Section {
                        TextField("Country code, e.g. in or us", text: $storeCountry)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } header: {
                        Text("App Store country")
                    } footer: {
                        Text("Searching uses the \(AppStore.country.uppercased()) store, then the US store if nothing is found. Leave empty to follow your iPhone's region.")
                    }
                    Section("Storage") {
                        LabeledContent("Folders saved in", value: Store.mode)
                    }
                    Section {
                        Text(widgetLog.isEmpty ? "The widget hasn't run yet." : widgetLog)
                            .font(.system(.caption, design: .monospaced))
                        Button("Refresh widgets + log") {
                            WidgetCenter.shared.reloadAllTimelines()
                            widgetLog = WidgetLog.read()
                        }
                    } header: {
                        Text("Widget log")
                    } footer: {
                        Text("Newest first. If a widget stays grey, send a screenshot of this.")
                    }
                    Section("Signing") {
                        LabeledContent("Team", value: Entitlements.teamID ?? "?")
                        LabeledContent("App Groups", value: Entitlements.appGroups.isEmpty ? "none" : Entitlements.appGroups.joined(separator: "\n"))
                        LabeledContent("Keychain", value: Entitlements.keychainGroups.isEmpty ? "none" : Entitlements.keychainGroups.joined(separator: "\n"))
                    }
                }
                .listRowBackground(Theme.pocket)
            }
            .walletList()
            .navigationTitle("About Tuck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
