import SwiftUI

/// S04: add apps from the App Store, the installed-app check, Apple's built-in apps, or by bundle ID.
struct AddAppView: View {
    enum Source: String, CaseIterable {
        case store = "App Store"
        case installed = "Installed"
        case apple = "Apple"
        case custom = "Custom"
    }

    let folderID: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var source = Source.store

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Source", selection: $source) {
                    ForEach(Source.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                switch source {
                case .store: StoreSearchList(folderID: folderID)
                case .installed: InstalledAppsList(folderID: folderID)
                case .apple: AppleAppsList(folderID: folderID)
                case .custom: CustomAppForm(folderID: folderID)
                }
            }
            .background(Theme.ground.ignoresSafeArea())
            .navigationTitle("Add apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

/// One tappable row: icon, name, subtitle, and whether the folder has it.
private struct PickRow: View {
    let app: AppRef
    let subtitle: String
    let folderID: UUID
    @EnvironmentObject private var model: LibraryModel

    var body: some View {
        Button { model.toggle(app, in: folderID) } label: {
            HStack(spacing: 12) {
                LoadedIcon(app: app, size: 40)
                VStack(alignment: .leading) {
                    Text(app.name).lineLimit(1)
                    Text(subtitle).font(.caption).foregroundStyle(Theme.embossSoft).lineLimit(1)
                }
                Spacer()
                Image(systemName: model.contains(app.bundleId, in: folderID) ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title3)
                    .foregroundStyle(Theme.cognac)
            }
        }
        .tint(.primary)
    }
}

struct StoreSearchList: View {
    let folderID: UUID
    @EnvironmentObject private var model: LibraryModel
    @State private var query = ""
    @State private var results: [AppStore.Result] = []
    @State private var status = "Type an app's name"

    /// Apps already in any folder, once each, for quick re-adding.
    private var known: [AppRef] {
        var seen = Set<String>()
        return model.library.folders.flatMap(\.apps).filter { seen.insert($0.bundleId).inserted }
    }

    var body: some View {
        List {
            Group {
                Label {
                    TextField("Search the App Store (\(AppStore.country.uppercased()))", text: $query)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } icon: {
                    Image(systemName: "magnifyingglass").foregroundStyle(Theme.embossSoft)
                }
                if results.isEmpty && !query.isEmpty {
                    Text(status).foregroundStyle(Theme.embossSoft)
                }
                ForEach(results) { result in
                    PickRow(app: result.appRef, subtitle: result.sellerName ?? "", folderID: folderID)
                }
                if query.isEmpty && !known.isEmpty {
                    Section {
                        ForEach(known) { app in
                            PickRow(app: app, subtitle: app.bundleId, folderID: folderID)
                        }
                    } header: {
                        Text("Apps in your folders").foregroundStyle(Theme.embossSoft)
                    }
                }
            }
            .listRowBackground(Theme.pocket)
        }
        .walletList()
        .task(id: query) { await search() }
    }

    private func search() async {
        let term = query.trimmingCharacters(in: .whitespaces)
        guard term.count >= 2 else {
            results = []
            status = "Type an app's name"
            return
        }
        try? await Task.sleep(for: .milliseconds(400)) // wait until typing pauses
        guard !Task.isCancelled else { return }
        status = "Searching…"
        do {
            results = try await AppStore.search(term)
            status = results.isEmpty ? "No apps found. Try another spelling." : ""
        } catch {
            if !Task.isCancelled { status = "Search failed: \(error.localizedDescription)" }
        }
    }
}

/// Checks the popular apps in KnownApps for being installed, then lets you tick several and add them.
struct InstalledAppsList: View {
    let folderID: UUID
    @EnvironmentObject private var model: LibraryModel
    @State private var found: [AppStore.Result] = []
    @State private var picked: Set<String> = []
    @State private var status = "Looking for installed apps…"

    var body: some View {
        List {
            Group {
                Section {
                    if found.isEmpty {
                        Text(status).foregroundStyle(Theme.embossSoft)
                    }
                    ForEach(found) { result in
                        let inFolder = model.contains(result.bundleId, in: folderID)
                        Button {
                            if picked.contains(result.bundleId) { picked.remove(result.bundleId) } else { picked.insert(result.bundleId) }
                        } label: {
                            HStack(spacing: 12) {
                                LoadedIcon(app: result.appRef, size: 40)
                                VStack(alignment: .leading) {
                                    Text(result.trackName).lineLimit(1)
                                    Text(inFolder ? "Already in this folder" : result.sellerName ?? "")
                                        .font(.caption).foregroundStyle(Theme.embossSoft).lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: inFolder || picked.contains(result.bundleId) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(inFolder ? Theme.embossSoft : Theme.cognac)
                            }
                        }
                        .tint(.primary)
                        .disabled(inFolder)
                    }
                } footer: {
                    Text("Checks \(KnownApps.bundleIds.count) popular apps. Others can still be added from App Store or Custom.")
                }
                if !picked.isEmpty {
                    Section {
                        Button("Add \(picked.count) apps") {
                            for result in found where picked.contains(result.bundleId) {
                                model.toggle(result.appRef, in: folderID)
                            }
                            picked = []
                        }
                        .bold()
                    }
                }
            }
            .listRowBackground(Theme.pocket)
        }
        .walletList()
        .task { await scan() }
    }

    private func scan() async {
        var installed: [String] = []
        for id in KnownApps.bundleIds {
            switch PrivateApps.isInstalled(id) {
            case nil:
                status = "This iPhone doesn't let Tuck check which apps are installed."
                return
            case true?:
                installed.append(id)
            default:
                break
            }
        }
        guard !installed.isEmpty else {
            status = "None of the \(KnownApps.bundleIds.count) apps Tuck knows were found."
            return
        }
        status = "Found \(installed.count) apps. Loading their icons…"
        found = await AppStore.lookup(bundleIds: installed)
            .sorted { $0.trackName.localizedCaseInsensitiveCompare($1.trackName) == .orderedAscending }
        if found.isEmpty {
            status = "Found \(installed.count) apps but couldn't load their details from the App Store."
        }
    }
}

struct AppleAppsList: View {
    let folderID: UUID

    var body: some View {
        List(AppleApps.all, id: \.bundleId) { app in
            PickRow(app: app, subtitle: "Apple", folderID: folderID)
                .listRowBackground(Theme.pocket)
        }
        .walletList()
    }
}

/// Apps that aren't in the App Store (your own builds, sideloaded open-source apps).
struct CustomAppForm: View {
    enum Style: String, CaseIterable {
        case store = "App Store"
        case letter = "Letter"
        case symbol = "Symbol"
        case image = "URL"
    }

    let folderID: UUID
    @EnvironmentObject private var model: LibraryModel
    @State private var name = ""
    @State private var bundleId = ""
    @State private var style = Style.store
    @State private var symbol = "app.fill"
    @State private var imageURL = ""
    @State private var colorHex = Palette.folderColors[0]
    @State private var testResult: String?
    @State private var storeQuery = ""
    @State private var storeResults: [AppStore.Result] = []
    @State private var storeArtwork: URL?

    private var cleanBundleId: String { bundleId.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var icon: IconSource {
        switch style {
        case .store: return storeArtwork.map { .artwork($0) } ?? .letter(colorHex: colorHex)
        case .letter: return .letter(colorHex: colorHex)
        case .symbol: return .symbol(name: symbol, colorHex: colorHex)
        case .image:
            guard let url = URL(string: imageURL), url.scheme?.hasPrefix("http") == true else {
                return .letter(colorHex: colorHex)
            }
            return .artwork(url)
        }
    }

    private var draft: AppRef {
        AppRef(id: UUID(), name: name.isEmpty ? cleanBundleId : name, bundleId: cleanBundleId, icon: icon)
    }

    var body: some View {
        Form {
            Group {
                Section {
                    TextField("Name", text: $name)
                    TextField("Bundle ID, e.g. com.ytmusic.app", text: $bundleId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    Button("Test open") {
                        testResult = PrivateApps.openBundle(cleanBundleId)
                            ? nil
                            : "Couldn't open \(cleanBundleId). Check the bundle ID in your signer app."
                    }
                    .disabled(cleanBundleId.isEmpty)
                    if let testResult {
                        Text(testResult).font(.footnote).foregroundStyle(.red)
                    }
                } header: {
                    Text("App")
                } footer: {
                    Text("Use the bundle ID the app has on this iPhone. Signers can change it, so copy it from the app you signed with.")
                }

                Section("Icon") {
                    Picker("Style", selection: $style) {
                        ForEach(Style.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    switch style {
                    case .store:
                        TextField("Search the App Store for its icon", text: $storeQuery)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        ForEach(storeResults.prefix(5)) { result in
                            Button {
                                storeArtwork = result.artworkUrl512 ?? result.artworkUrl100
                                if name.isEmpty { name = result.trackName }
                            } label: {
                                HStack(spacing: 12) {
                                    LoadedIcon(app: result.appRef, size: 32)
                                    Text(result.trackName).lineLimit(1)
                                    Spacer()
                                    if storeArtwork != nil && storeArtwork == (result.artworkUrl512 ?? result.artworkUrl100) {
                                        Image(systemName: "checkmark").foregroundStyle(Theme.cognac)
                                    }
                                }
                            }
                            .tint(.primary)
                        }
                    case .symbol:
                        TextField("SF Symbol name", text: $symbol)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    case .image:
                        TextField("https://…/icon.png", text: $imageURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                    case .letter:
                        EmptyView()
                    }
                    if style == .letter || style == .symbol {
                        ColorSwatches(selection: $colorHex)
                    }
                    HStack {
                        Spacer()
                        LoadedIcon(app: draft, size: 64)
                        Spacer()
                    }
                }

                Section {
                    Button("Add to folder") {
                        model.toggle(draft, in: folderID)
                        name = ""
                        bundleId = ""
                        imageURL = ""
                        storeQuery = ""
                        storeArtwork = nil
                        testResult = nil
                    }
                    .disabled(cleanBundleId.isEmpty || model.contains(cleanBundleId, in: folderID))
                }
            }
            .listRowBackground(Theme.pocket)
        }
        .walletList()
        .task(id: storeQuery) {
            let term = storeQuery.trimmingCharacters(in: .whitespaces)
            guard term.count >= 2 else {
                storeResults = []
                return
            }
            try? await Task.sleep(for: .milliseconds(400)) // wait until typing pauses
            guard !Task.isCancelled else { return }
            storeResults = (try? await AppStore.search(term)) ?? []
        }
    }
}
