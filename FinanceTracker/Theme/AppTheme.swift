//
//  AppTheme.swift
//  Finna
//
//  Centralized design tokens — colors, typography, corner radii, and view styles.
//  Per CLAUDE.md: ALL colors must come from here. Never hardcode hex elsewhere.
//

import SwiftUI

// MARK: - Hex Color Initializer

extension Color {
    /// Creates a Color from a hex string. Supports "#RRGGBB" and "RRGGBB".
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let r, g, b, a: Double
        switch cleaned.count {
        case 6:
            r = Double((rgb & 0xFF0000) >> 16) / 255
            g = Double((rgb & 0x00FF00) >> 8) / 255
            b = Double(rgb & 0x0000FF) / 255
            a = 1
        case 8:
            r = Double((rgb & 0xFF000000) >> 24) / 255
            g = Double((rgb & 0x00FF0000) >> 16) / 255
            b = Double((rgb & 0x0000FF00) >> 8) / 255
            a = Double(rgb & 0x000000FF) / 255
        default:
            r = 0; g = 0; b = 0; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Creates a Color that resolves differently in light vs dark mode.
    init(light: String, dark: String) {
        self.init(UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(Color(hex: hex))
        })
    }
}

// MARK: - AppTheme

enum AppTheme {

    // MARK: Colors
    // Light values from CLAUDE.md; dark values are the warm-brown adaptation per PRD §5.1.
    enum Colors {
        static let background  = Color(light: "#FAFBFF", dark: "#0E0F1A")
        static let surface     = Color(light: "#FFFFFF", dark: "#161828")
        static let accent      = Color(light: "#4B6BCC", dark: "#7B8FD4")
        static let accentAlt   = Color(light: "#3A5AB8", dark: "#6A7EC4")
        static let income      = Color(light: "#2E8E6E", dark: "#5AAAC8")
        static let expense     = Color(light: "#B85450", dark: "#D47878")
        static let danger      = Color(light: "#C0392B", dark: "#E0564A")
        static let textPrimary = Color(light: "#1A1F3C", dark: "#EEEEF8")
        static let textMuted   = Color(light: "#6470A0", dark: "#8888AA")
        static let textDim     = Color(light: "#9AA0C4", dark: "#6A6A88")
        static let border      = Color(light: "#E2E5F0", dark: "#2A2D45")
        static let borderAlt   = Color(light: "#D0D4EC", dark: "#363A58")
        // Hero balance card — bold brand blue-purple with white text in both modes.
        static let heroCard    = Color(light: "#5567BB", dark: "#4A5DB0")
        static let heroCardAlt = Color(light: "#4558AA", dark: "#3A4D9F")
        // Accent used for the active-trip banner.
        static let teal        = Color(light: "#2A7A9B", dark: "#5FBEB6")
        // Budget alert at 80–99% of limit (100%+ uses `expense`).
        static let warning     = Color(light: "#E0924A", dark: "#E0A24E")

        // Curated blue-purple palette for chart slices, in order for up to 8
        // categories (sorted by amount descending). Same in both modes.
        static let chartPalette: [Color] = [
            Color(hex: "#4A5DB0"), Color(hex: "#7B8FD4"), Color(hex: "#A78FD4"),
            Color(hex: "#D4A8D4"), Color(hex: "#5AAAC8"), Color(hex: "#7BC4B0"),
            Color(hex: "#B0C47B"), Color(hex: "#D4B87B"),
        ]

        // MARK: Pastel Palette
        // Soft tinted card system. Each pastel has three roles:
        //   fill  — the card background tint
        //   badge — the icon circle behind an SF Symbol
        //   text  — the symbol/icon and accent text color
        // Assigned to items via `PastelStyle` and `IconMap.pastel(forIndex:)`.
        // Dark values are muted (~20% brightness) versions of the same hue,
        // with a slightly lighter badge and a light, readable text color.

        static let pastelPeachFill  = Color(light: "#FDEEE6", dark: "#33271F")
        static let pastelPeachBadge = Color(light: "#F5D5C4", dark: "#5C4636")
        static let pastelPeachText  = Color(light: "#B5603A", dark: "#E8B89C")

        static let pastelLavenderFill  = Color(light: "#EDEAFB", dark: "#262338")
        static let pastelLavenderBadge = Color(light: "#D5CEF3", dark: "#423C66")
        static let pastelLavenderText  = Color(light: "#5A4D9F", dark: "#C4BCF0")

        static let pastelMintFill  = Color(light: "#E3F4EC", dark: "#1E322A")
        static let pastelMintBadge = Color(light: "#C2E6D3", dark: "#335248")
        static let pastelMintText  = Color(light: "#2E8E6E", dark: "#9FD9BE")

        static let pastelSkyFill  = Color(light: "#E5F0FC", dark: "#1F2C3A")
        static let pastelSkyBadge = Color(light: "#C2DCF5", dark: "#38516B")
        static let pastelSkyText  = Color(light: "#3A6BB5", dark: "#A6CBEF")

        static let pastelRoseFill  = Color(light: "#FBEAF1", dark: "#33232C")
        static let pastelRoseBadge = Color(light: "#F3CADE", dark: "#5C3E4E")
        static let pastelRoseText  = Color(light: "#B54B7E", dark: "#E8AAC8")

        static let pastelSandFill  = Color(light: "#FCF3E0", dark: "#322C1C")
        static let pastelSandBadge = Color(light: "#F5E2B8", dark: "#564B2E")
        static let pastelSandText  = Color(light: "#A87A1E", dark: "#DEC68A")

        // Gradient for the hero balance card — bright sky blue into brand blue-purple.
        static var heroGradient: LinearGradient {
            LinearGradient(
                colors: [Color(hex: "#8FB4F0"), Color(hex: "#5567BB")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: Corner Radius
    enum Radius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 20
    }

    // MARK: Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
    }

    // MARK: Typography Scale
    // All SF Pro. Hierarchy comes from weight + size contrast, not serif.
    enum Typography {
        static let fontBalance: CGFloat = 34      // main balance number, weight .thin
        static let fontTitle: CGFloat = 22        // screen titles, weight .semibold
        static let fontCardNumber: CGFloat = 17   // card amounts, weight .semibold
        static let fontBody: CGFloat = 14         // standard body, weight .regular
        static let fontLabel: CGFloat = 12        // labels and subtitles, weight .medium
        static let fontCaption: CGFloat = 10      // section headers, weight .semibold

        static let trackingTight: CGFloat = -0.5  // applied to balance and large amounts
    }
}

// MARK: - Typography Helpers

extension Font {
    /// Formerly a serif face. Now all SF Pro — hierarchy comes from weight, not design.
    /// Kept for existing call sites that used it for balance figures and headings.
    static func appSerif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// SF Pro system sans — body text, labels, buttons.
    static func appSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Monospaced SF Pro — for large numerals that benefit from tabular alignment.
    static func appMono(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Card Style

struct CardStyle: ViewModifier {
    var padding: CGFloat = AppTheme.Spacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
            // Soft floating shadow (Ofspace-inspired) — no border.
            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
    }
}

extension View {
    /// Applies the standard surface card treatment (background, radius, soft shadow).
    func cardStyle(padding: CGFloat = AppTheme.Spacing.md) -> some View {
        modifier(CardStyle(padding: padding))
    }
}

// MARK: - Pastel Style

/// One of the six pastel card themes. Each case exposes the `fill`, `badge`, and
/// `text` colors for that pastel. The colors are `Color(light:dark:)` values, so
/// they resolve automatically for the current color scheme — no scheme needs to
/// be passed in. Assign one to an item with `IconMap.pastel(forIndex:)`.
enum PastelStyle: CaseIterable {
    case peach, lavender, mint, sky, rose, sand

    /// Soft card-background tint.
    var fill: Color {
        switch self {
        case .peach:    return AppTheme.Colors.pastelPeachFill
        case .lavender: return AppTheme.Colors.pastelLavenderFill
        case .mint:     return AppTheme.Colors.pastelMintFill
        case .sky:      return AppTheme.Colors.pastelSkyFill
        case .rose:     return AppTheme.Colors.pastelRoseFill
        case .sand:     return AppTheme.Colors.pastelSandFill
        }
    }

    /// Circular badge color behind the SF Symbol icon.
    var badge: Color {
        switch self {
        case .peach:    return AppTheme.Colors.pastelPeachBadge
        case .lavender: return AppTheme.Colors.pastelLavenderBadge
        case .mint:     return AppTheme.Colors.pastelMintBadge
        case .sky:      return AppTheme.Colors.pastelSkyBadge
        case .rose:     return AppTheme.Colors.pastelRoseBadge
        case .sand:     return AppTheme.Colors.pastelSandBadge
        }
    }

    /// Symbol/icon and accent-text color.
    var text: Color {
        switch self {
        case .peach:    return AppTheme.Colors.pastelPeachText
        case .lavender: return AppTheme.Colors.pastelLavenderText
        case .mint:     return AppTheme.Colors.pastelMintText
        case .sky:      return AppTheme.Colors.pastelSkyText
        case .rose:     return AppTheme.Colors.pastelRoseText
        case .sand:     return AppTheme.Colors.pastelSandText
        }
    }
}
