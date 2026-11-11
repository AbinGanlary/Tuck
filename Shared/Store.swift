import Foundation
import Security

/// Where the folders live. The App Group file when signing grants one; otherwise a keychain item
/// in the default group, which the launch test showed the app and widget share.
enum Store {
    private static let account = "library"
    private static var file: URL? { Shared.container?.appendingPathComponent("library.json") }

    static var mode: String { file == nil ? "Keychain" : "App Group (\(Shared.appGroup))" }

    static func load() -> Library {
        let data = file.flatMap { try? Data(contentsOf: $0) } ?? SharedKeychain.read(account: account)
        return data.flatMap { try? JSONDecoder().decode(Library.self, from: $0) } ?? Library()
    }

    static func save(_ library: Library) throws {
        let data = try JSONEncoder().encode(library)
        if let file {
            try data.write(to: file, options: .atomic)
            return
        }
        let status = SharedKeychain.write(data, account: account)
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }
}

/// Small shared files the widget reads (icon copies, photos, its log): files in the App Group when
/// signing grants one, else keychain items in the default group.
enum SharedBlobs {
    private static var dir: URL? { Shared.container?.appendingPathComponent("shared", isDirectory: true) }

    @discardableResult
    static func write(_ data: Data, account: String) -> OSStatus {
        guard let dir else { return SharedKeychain.write(data, account: account) }
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try data.write(to: dir.appendingPathComponent(account), options: .atomic)
            return errSecSuccess
        } catch {
            return errSecIO
        }
    }

    static func read(account: String) -> Data? {
        guard let dir else { return SharedKeychain.read(account: account) }
        return try? Data(contentsOf: dir.appendingPathComponent(account))
    }
}
