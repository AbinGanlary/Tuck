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
    /// tuck://open?url=<launch link>: the bounce route, where Tuck opens the link itself.
    var bounceURL: URL? {
        guard let launchURL else { return nil }
        var c = URLComponents()
        c.scheme = "tuck"
        c.host = "open"
        c.queryItems = [URLQueryItem(name: "url", value: launchURL.absoluteString)]
        return c.url
    }
}
