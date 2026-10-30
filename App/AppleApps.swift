import Foundation

/// Apple's built-in apps. They aren't all in the App Store search, and their icons come from
/// the phone itself.
enum AppleApps {
    private static let list: [(String, String)] = [
        ("App Store", "com.apple.AppStore"),
        ("Books", "com.apple.iBooks"),
        ("Calculator", "com.apple.calculator"),
        ("Calendar", "com.apple.mobilecal"),
        ("Camera", "com.apple.camera"),
        ("Clock", "com.apple.mobiletimer"),
        ("Compass", "com.apple.compass"),
        ("Contacts", "com.apple.MobileAddressBook"),
        ("FaceTime", "com.apple.facetime"),
        ("Files", "com.apple.DocumentsApp"),
        ("Find My", "com.apple.findmy"),
        ("Fitness", "com.apple.Fitness"),
        ("Freeform", "com.apple.freeform"),
        ("Games", "com.apple.games"),
        ("Health", "com.apple.Health"),
        ("Home", "com.apple.Home"),
        ("Journal", "com.apple.journal"),
        ("Magnifier", "com.apple.Magnifier"),
        ("Mail", "com.apple.mobilemail"),
        ("Maps", "com.apple.Maps"),
        ("Measure", "com.apple.measure"),
        ("Messages", "com.apple.MobileSMS"),
        ("Music", "com.apple.Music"),
        ("Notes", "com.apple.mobilenotes"),
        ("Passwords", "com.apple.Passwords"),
        ("Phone", "com.apple.mobilephone"),
        ("Photos", "com.apple.mobileslideshow"),
        ("Podcasts", "com.apple.podcasts"),
        ("Preview", "com.apple.Preview"),
        ("Reminders", "com.apple.reminders"),
        ("Safari", "com.apple.mobilesafari"),
        ("Settings", "com.apple.Preferences"),
        ("Shortcuts", "com.apple.shortcuts"),
        ("Stocks", "com.apple.stocks"),
        ("Tips", "com.apple.tips"),
        ("Translate", "com.apple.Translate"),
        ("TV", "com.apple.tv"),
        ("Voice Memos", "com.apple.VoiceMemos"),
        ("Wallet", "com.apple.Passbook"),
        ("Watch", "com.apple.Bridge"),
        ("Weather", "com.apple.weather"),
    ]

    static let all: [AppRef] = list.map { AppRef(id: UUID(), name: $0.0, bundleId: $0.1, icon: .system) }
}
