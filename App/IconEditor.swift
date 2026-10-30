import PhotosUI
import SwiftUI

/// Change one app's icon in a folder: an App Store icon, a photo, a letter or a symbol.
struct IconEditor: View {
    enum Style: String, CaseIterable {
        case store = "App Store"
        case photo = "Photo"
        case letter = "Letter"
        case symbol = "Symbol"
    }

    let folderID: UUID
    let app: AppRef
    @EnvironmentObject private var model: LibraryModel
    @Environment(\.dismiss) private var dismiss
    @State private var style = Style.store
    @State private var query = ""
    @State private var results: [AppStore.Result] = []
    @State private var artwork: URL?
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var symbol = "app.fill"
    @State private var colorHex = Palette.folderColors[0]
    @State private var failure: String?

    /// The icon as chosen so far; the app's current one until something is picked.
    private var draftIcon: IconSource {
        switch style {
        case .store: return artwork.map { .artwork($0) } ?? app.icon
        case .photo: return app.icon // shown from photoData until saved
        case .letter: return .letter(colorHex: colorHex)
        case .symbol: return .symbol(name: symbol, colorHex: colorHex)
        }
    }

    private var draft: AppRef {
        var copy = app
        copy.icon = draftIcon
        return copy
    }

    var body: some View {
        NavigationStack {
            Form {
                Group {
                    Section {
                        HStack {
                            Spacer()
                            if style == .photo, let photoData, let image = UIImage(data: photoData) {
                                AppIconView(app: app, image: image, size: 72)
                            } else {
                                LoadedIcon(app: draft, size: 72)
                            }
                            Spacer()
                        }
                        Picker("Style", selection: $style) {
                            ForEach(Style.allCases, id: \.self) { Text($0.rawValue) }
                        }
                        .pickerStyle(.segmented)
                    }

                    switch style {
                    case .store:
                        Section {
                            TextField("Search the App Store", text: $query)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            ForEach(results.prefix(8)) { result in
                                Button {
                                    artwork = result.artworkUrl512 ?? result.artworkUrl100
                                } label: {
                                    HStack(spacing: 12) {
                                        LoadedIcon(app: result.appRef, size: 32)
                                        Text(result.trackName).lineLimit(1)
                                    }
                                }
                                .tint(.primary)
                            }
                        }
                    case .photo:
                        Section {
                            PhotosPicker(selection: $photoItem, matching: .images) {
                                Label(photoData == nil ? "Choose a photo" : "Choose another photo", systemImage: "photo")
                            }
                        } footer: {
                            Text("The middle square of the photo becomes the icon.")
                        }
                    case .letter, .symbol:
                        Section {
                            if style == .symbol {
                                TextField("SF Symbol name", text: $symbol)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                            ColorSwatches(selection: $colorHex)
                        }
                    }

                    if let failure {
                        Text(failure).foregroundStyle(.red)
                    }
                }
                .listRowBackground(Theme.pocket)
            }
            .walletList()
            .navigationTitle(app.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .task(id: query) {
                let term = query.trimmingCharacters(in: .whitespaces)
                guard term.count >= 2 else { return }
                try? await Task.sleep(for: .milliseconds(400)) // wait until typing pauses
                guard !Task.isCancelled else { return }
                results = (try? await AppStore.search(term)) ?? []
            }
            .task(id: photoItem) {
                photoData = try? await photoItem?.loadTransferable(type: Data.self)
            }
            .onAppear { query = app.name }
        }
    }

    private func save() {
        var icon = draftIcon
        if style == .photo {
            guard let photoData, let id = IconCache.savePhoto(photoData) else {
                failure = "Choose a photo first."
                return
            }
            icon = .photo(id)
        }
        model.modify(folderID) { folder in
            if let i = folder.apps.firstIndex(where: { $0.id == app.id }) {
                folder.apps[i].icon = icon
            }
        }
        dismiss()
    }
}
