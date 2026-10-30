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
