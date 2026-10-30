import Foundation
import Security

/// Where the folders live. The App Group file when signing grants one; otherwise a keychain item
/// in the default group, which the launch test showed the app and widget share.
enum Store {
    private static let account = "library"
    private static var file: URL? { Shared.container?.appendingPathComponent("library.json") }

    static var mode: String { file == nil ? "Keychain" : "App Group" }

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
