import UIKit

/// Private LaunchServices / UIKit calls. Sideload-only: the App Store would reject them.
enum PrivateApps {
    private static var workspace: NSObject? {
        guard let cls: AnyClass = NSClassFromString("LSApplicationWorkspace") else { return nil }
        return (cls as AnyObject).perform(NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue() as? NSObject
    }

    /// Opens any installed app, App Store or sideloaded. false when it isn't installed.
    @discardableResult
    static func openBundle(_ bundleId: String) -> Bool {
        typealias Fn = @convention(c) (AnyObject, Selector, NSString) -> Bool
        let sel = NSSelectorFromString("openApplicationWithBundleID:")
        guard let ws = workspace, ws.responds(to: sel) else { return false }
        let fn = unsafeBitCast(ws.method(for: sel), to: Fn.self)
        return fn(ws, sel, bundleId as NSString)
    }

    /// Whether an app is installed, without opening it. nil when this iOS hides the call.
    static func isInstalled(_ bundleId: String) -> Bool? {
        typealias Fn = @convention(c) (AnyObject, Selector, NSString) -> Bool
        let sel = NSSelectorFromString("applicationIsInstalled:")
        guard let ws = workspace, ws.responds(to: sel) else { return nil }
        let fn = unsafeBitCast(ws.method(for: sel), to: Fn.self)
        return fn(ws, sel, bundleId as NSString)
    }

    /// The Home Screen icon. Only works for Apple's own apps; third-party apps come back blank.
    static func icon(_ bundleId: String) -> UIImage? {
        typealias Fn = @convention(c) (AnyObject, Selector, NSString, Int32, CGFloat) -> Unmanaged<UIImage>?
        let sel = NSSelectorFromString("_applicationIconImageForBundleIdentifier:format:scale:")
        guard let method = class_getClassMethod(UIImage.self, sel) else { return nil }
        let fn = unsafeBitCast(method_getImplementation(method), to: Fn.self)
        return fn(UIImage.self, sel, bundleId as NSString, 2, 3)?.takeUnretainedValue()
    }
}
