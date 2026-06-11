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
        static let background  = Color(light: "#F0F2FA", dark: "#0E0F1A")
        static let surface     = Color(light: "#FFFFFF", dark: "#161828")
        static let accent      = Color(light: "#4A5DB0", dark: "#7B8FD4")
        static let accentAlt   = Color(light: "#3A4D9F", dark: "#6A7EC4")
        static let income      = Color(light: "#2E8E6E", dark: "#5AAAC8")
        static let expense     = Color(light: "#B85450", dark: "#D47878")
        static let danger      = Color(light: "#C0392B", dark: "#E0564A")
        static let textPrimary = Color(light: "#1A1F3C", dark: "#EEEEF8")
        static let textMuted   = Color(light: "#6470A0", dark: "#8888AA")
        static let textDim     = Color(light: "#9AA0C4", dark: "#6A6A88")
        static let border      = Color(light: "#E2E5F0", dark: "#2A2D45")
        static let borderAlt   = Color(light: "#D0D4EC", dark: "#363A58")
        // Hero balance card — bold brand blue-purple with white text in both modes.
        static let heroCard    = Color(light: "#4A5DB0", dark: "#4A5DB0")
        static let heroCardAlt = Color(light: "#3A4D9F", dark: "#3A4D9F")
        // Accent used for the active-trip banner.
        static let teal        = Color(light: "#2A7A9B", dark: "#5FBEB6")
        // Budget alert at 80–99% of limit (100%+ uses `expense`).
        static let warning     = Color(light: "#B07A20", dark: "#E0A24E")
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
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

extension View {
    /// Applies the standard surface card treatment (background, radius, soft shadow).
    func cardStyle(padding: CGFloat = AppTheme.Spacing.md) -> some View {
        modifier(CardStyle(padding: padding))
    }
}
