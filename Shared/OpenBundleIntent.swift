import AppIntents

/// Widget row E: the intent runs in the widget's own process and opens the target by bundle ID,
/// hopefully without bringing Tuck to the front first.
struct OpenBundleIntent: AppIntent {
    static var title: LocalizedStringResource = "Open app by bundle ID"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Bundle ID")
    var bundleId: String

    init() {}

    init(bundleId: String) {
        self.bundleId = bundleId
    }

    func perform() async throws -> some IntentResult {
        _ = PrivateApps.openBundle(bundleId)
        return .result()
    }
}

/// The "Direct" way to open a LiveContainer link: like row E, from the widget's own process.
struct OpenLinkIntent: AppIntent {
    static var title: LocalizedStringResource = "Open link"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Link")
    var url: URL

    init() {}

    init(url: URL) {
        self.url = url
    }

    func perform() async throws -> some IntentResult {
        let opened = PrivateApps.openURL(url)
        WidgetLog.write("direct \(url.scheme ?? "?"): \(opened ? "opened" : "FAILED")")
        return .result()
    }
}

extension AppRef {
    /// tuck://open?id=<item id>: the bounce route, where Tuck looks the launch link up and opens it.
    /// Only the id travels: a launch link carries its own ?…&… query, which nesting can mangle.
    var bounceURL: URL? {
        guard launchURL != nil else { return nil }
        return URL(string: "tuck://open?id=\(id.uuidString)")
    }
}
