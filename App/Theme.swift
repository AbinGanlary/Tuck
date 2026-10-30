import SwiftUI
import UIKit

/// The wallet palette: espresso leather in dark mode, saddle tan in light. Every colour adapts to
/// the appearance on its own, so views never branch on the colour scheme.
enum Theme {
    /// The screen behind everything: the inside of the wallet.
    static let ground = dynamic(light: "#E6D6C2", dark: "#14100D")
    /// A pocket or panel: one step lighter than the ground.
    static let pocket = dynamic(light: "#F1E6D8", dark: "#221A15")
    /// Pocket fronts sit over the apps: a touch lighter again.
    static let pocketFront = dynamic(light: "#F7EEE3", dark: "#2B211B")
    /// The dashed stitch along pocket edges.
    static let stitch = dynamic(light: "#A27B55", dark: "#8C6A4C")
    /// Names pressed into the leather.
    static let emboss = dynamic(light: "#3B2A1E", dark: "#F3E2C7")
    /// Secondary text on leather, tinted from it rather than grey.
    static let embossSoft = dynamic(light: "#7A5E47", dark: "#B79C80")
    /// The one tint: everything pressable.
    static let cognac = dynamic(light: "#9A5B26", dark: "#D9944F")

    private static func dynamic(light: String, dark: String) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light)) })
    }
}

/// A leather pocket: filled, with a dashed stitch running just inside its edge and a soft drop.
struct StitchedPanel: View {
    var fill = Theme.pocket
    var cornerRadius: CGFloat = 22

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(fill)
            .overlay(
                shape.inset(by: 5)
                    .stroke(Theme.stitch.opacity(0.75), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
            )
            .shadow(color: .black.opacity(0.28), radius: 6, x: 0, y: 3)
    }
}

extension View {
    /// Lists and forms on the wallet ground, rows as pockets.
    func walletList() -> some View {
        scrollContentBackground(.hidden)
            .background(Theme.ground.ignoresSafeArea())
    }
}
