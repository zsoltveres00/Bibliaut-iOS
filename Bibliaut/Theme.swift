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

    static let bg        = adaptive("#F3F1FF", "#161327")
    static let surface   = adaptive("#FFFFFF", "#241F3B")
    static let text      = adaptive("#1E1B3A", "#F4F1FF")
    static let muted     = adaptive("#6B6690", "#A7A1C6")
    static let brand     = adaptive("#5B3FD1", "#A78BFA")
    static let brand2    = adaptive("#9B4DE0", "#E08BF7")
    static let brandInk  = adaptive("#FFFFFF", "#161327")
    static let bannerInk = Color(hex: "#FFFFFF")
    static let gold      = adaptive("#F2A900", "#FFC83D")
    /// Bright star yellow, readable on any of the section colours.
    static let star      = Color(hex: "#FFD23F")
    static let correct   = adaptive("#22A559", "#4ADE80")
    static let wrong     = adaptive("#E5484D", "#F87171")
    /// "Frozen" (missed) days in the statistics calendar.
    static let ice       = adaptive("#D6ECFF", "#243A5C")
    static let iceInk    = adaptive("#2F79C9", "#8FC4FF")
    static let chestWood = Color(hex: "#9A5B2C")
    static let chestLid  = Color(hex: "#B8712F")
    static let border    = adaptive(light: UIColor(red: 30/255, green: 27/255, blue: 58/255, alpha: 0.12),
                                    dark: UIColor(red: 244/255, green: 241/255, blue: 255/255, alpha: 0.14))
    static let shadow    = adaptive(light: UIColor(red: 60/255, green: 40/255, blue: 140/255, alpha: 0.14),
                                    dark: UIColor(white: 0, alpha: 0.45))

    /// Header / hero gradient.
    static let heroGradient = LinearGradient(colors: [brand, brand2], startPoint: .topLeading, endPoint: .bottomTrailing)
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

/// Treasure chest drawn from shapes: a wooden body with a gold band and lock, and a lid that
/// swings open (with sparkles) once the chest has been claimed.
struct ChestView: View {
    var open: Bool
    var size: CGFloat = 56

    var body: some View {
        let w = size
        let bodyH = w * 0.48
        let lidH = w * 0.34
        let band = w * 0.11
        VStack(spacing: 0) {
            ZStack {
                UnevenRoundedRectangle(topLeadingRadius: w * 0.26, bottomLeadingRadius: w * 0.04,
                                       bottomTrailingRadius: w * 0.04, topTrailingRadius: w * 0.26)
                    .fill(LinearGradient(colors: [Color.chestLid, Color.chestWood], startPoint: .top, endPoint: .bottom))
                UnevenRoundedRectangle(topLeadingRadius: w * 0.26, bottomLeadingRadius: w * 0.04,
                                       bottomTrailingRadius: w * 0.04, topTrailingRadius: w * 0.26)
                    .stroke(Color.chestWood.opacity(0.7), lineWidth: max(1, w / 40))
                Rectangle().fill(Color.gold).frame(width: band)
            }
            .frame(width: w, height: lidH)
            .rotation3DEffect(.degrees(open ? -70 : 0), axis: (x: 1, y: 0, z: 0),
                              anchor: .bottom, perspective: 0.5)
            .zIndex(open ? 0 : 1)

            ZStack {
                RoundedRectangle(cornerRadius: w * 0.08)
                    .fill(LinearGradient(colors: [Color.chestWood, Color.chestWood.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: w * 0.08)
                    .stroke(Color.chestWood.opacity(0.7), lineWidth: max(1, w / 40))
                Rectangle().fill(Color.gold).frame(height: band)
                    .frame(maxHeight: .infinity, alignment: .top)
                Rectangle().fill(Color.gold).frame(width: band)
                RoundedRectangle(cornerRadius: w * 0.05)
                    .fill(Color.gold)
                    .overlay(RoundedRectangle(cornerRadius: w * 0.05).stroke(Color.chestWood, lineWidth: max(1, w / 40)))
                    .frame(width: w * 0.22, height: w * 0.22)
                    .overlay(Circle().fill(Color.chestWood).frame(width: w * 0.07, height: w * 0.07))
                    .offset(y: -bodyH * 0.12)
                if open {
                    Image(systemName: "sparkles")
                        .font(.system(size: w * 0.42, weight: .bold))
                        .foregroundStyle(Color.star)
                        .shadow(color: Color.star.opacity(0.8), radius: w * 0.12)
                        .offset(y: -bodyH * 0.55)
                }
            }
            .frame(width: w, height: bodyH)
        }
        .frame(width: w, height: lidH + bodyH)
        .shadow(color: Color.shadow, radius: w * 0.06, y: w * 0.04)
    }
}

/// The star a finished station shows on the path: full for 3 stars, half for 2, an outline for 1.
struct StationStar: View {
    let stars: Int
    var size: CGFloat = 20

    var body: some View {
        Image(systemName: stars >= 3 ? "star.fill" : (stars == 2 ? "star.leadinghalf.filled" : "star"))
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(stars >= 2 ? Color.star : Color.white)
            .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
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
