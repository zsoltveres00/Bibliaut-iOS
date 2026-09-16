import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(red: CGFloat((v >> 16) & 0xFF) / 255,
                  green: CGFloat((v >> 8) & 0xFF) / 255,
                  blue: CGFloat(v & 0xFF) / 255,
                  alpha: 1)
    }
}

/// The web version's CSS palette, light + dark, as adaptive colors.
extension Color {
    init(hex: String) { self.init(uiColor: UIColor(hex: hex)) }

    static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }

    static func adaptive(_ light: String, _ dark: String) -> Color {
        adaptive(light: UIColor(hex: light), dark: UIColor(hex: dark))
    }

    static let bg        = adaptive("#EFE6D6", "#201B2E")
    static let surface   = adaptive("#FFFFFF", "#2B2440")
    static let text      = adaptive("#241F33", "#F1E9D8")
    static let muted     = adaptive("#6B6154", "#B7AC9A")
    static let brand     = adaptive("#5B2A3A", "#C07E93")
    static let brandInk  = adaptive("#FBF6EC", "#201B2E")
    static let bannerInk = Color(hex: "#FBF6EC")
    static let gold      = adaptive("#9C6E22", "#E0B563")
    static let correct   = adaptive("#3F7A4E", "#5FAE72")
    static let wrong     = adaptive("#A83B32", "#D46856")
    /// "Frozen" (missed) days in the statistics calendar.
    static let ice       = adaptive("#D9E7F2", "#2E4058")
    static let iceInk    = adaptive("#4A6B8A", "#9FBAD6")
    static let border    = adaptive(light: UIColor(red: 36/255, green: 31/255, blue: 51/255, alpha: 0.14),
                                    dark: UIColor(red: 241/255, green: 233/255, blue: 216/255, alpha: 0.14))
    static let shadow    = adaptive(light: UIColor(red: 36/255, green: 31/255, blue: 51/255, alpha: 0.10),
                                    dark: UIColor(white: 0, alpha: 0.4))
}

extension Font {
    /// Headings: the web app uses Spectral; New York (system serif) is the native stand-in.
    static func heading(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

// MARK: - Shared icons

/// The collectible currency: a gold coin stamped with a cross ("talentum", Matthew 25).
struct TalentCoin: View {
    var size: CGFloat = 18

    var body: some View {
        ZStack {
            Circle().fill(Color.gold)
            Circle()
                .stroke(Color.brandInk.opacity(0.55), lineWidth: max(1, size / 14))
                .padding(size / 7)
            Image(systemName: "cross.fill")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(Color.brandInk.opacity(0.85))
        }
        .frame(width: size, height: size)
    }
}

/// Treasure chest glyph used on the path, in the bottom bar and on the reward screen.
struct ChestIcon: View {
    var size: CGFloat = 26
    var color: Color = .gold

    var body: some View {
        Image(systemName: "archivebox.fill")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(color)
    }
}

// MARK: - Shared buttons

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.brandInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.brand, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.border, lineWidth: 1.5))
                .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

/// Underlined text link used for "‹ Back to the path".
struct BackLink: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .underline()
                .foregroundStyle(Color.muted)
        }
        .buttonStyle(.plain)
    }
}
