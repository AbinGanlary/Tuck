import Foundation
import Security

/// Reads this process's signed entitlements through SecTask (private on iOS, looked up at runtime).
enum Entitlements {
    private typealias CreateFn = @convention(c) (CFAllocator?) -> Unmanaged<AnyObject>?
    private typealias CopyFn = @convention(c) (AnyObject, CFString, UnsafeMutableRawPointer?) -> Unmanaged<AnyObject>?

    static func value(_ key: String) -> Any? {
        let any = UnsafeMutableRawPointer(bitPattern: -2) // RTLD_DEFAULT
        guard let c = dlsym(any, "SecTaskCreateFromSelf"),
              let v = dlsym(any, "SecTaskCopyValueForEntitlement") else { return nil }
        let create = unsafeBitCast(c, to: CreateFn.self)
        let copy = unsafeBitCast(v, to: CopyFn.self)
        guard let task = create(nil)?.takeRetainedValue() else { return nil }
        return copy(task, key as CFString, nil)?.takeRetainedValue()
    }

    static var appGroups: [String] { value("com.apple.security.application-groups") as? [String] ?? [] }
    static var keychainGroups: [String] { value("keychain-access-groups") as? [String] ?? [] }
    static var teamID: String? { value("com.apple.developer.team-identifier") as? String }

    static var summary: String {
        "team \(teamID ?? "?") · groups \(appGroups.isEmpty ? "none" : appGroups.joined(separator: ",")) · keychain \(keychainGroups.isEmpty ? "none" : keychainGroups.joined(separator: ","))"
    }
}

/// Shared storage when the App Group is missing: an item in the default keychain group
/// (the first signed one), which the launch test showed the app and widget both reach.
enum SharedKeychain {
    private static func query(_ account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "tuck",
         kSecAttrAccount as String: account]
    }

    static func write(_ data: Data, account: String) -> OSStatus {
        SecItemDelete(query(account) as CFDictionary)
        var add = query(account)
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(add as CFDictionary, nil)
    }

    static func read(account: String) -> Data? {
        var q = query(account)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        return SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess ? out as? Data : nil
    }
}
