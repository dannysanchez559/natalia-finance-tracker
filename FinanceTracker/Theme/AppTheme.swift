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
        static let background  = Color(light: "#FAFAF8", dark: "#1A1512")
        static let surface     = Color(light: "#FFFFFF", dark: "#241E1A")
        static let accent      = Color(light: "#A8796A", dark: "#C49A8B")
        static let income      = Color(light: "#5A8C6A", dark: "#7FB58F")
        static let expense     = Color(light: "#B86A5A", dark: "#D98B7B")
        static let textPrimary = Color(light: "#1A1410", dark: "#F2EDE7")
        static let textMuted   = Color(light: "#8A7A6E", dark: "#A89A8E")
        static let border      = Color(light: "#EAE4DC", dark: "#3A322C")
        // Accent used for the active-trip banner.
        static let teal        = Color(light: "#3AA39B", dark: "#5FBEB6")
        // Budget alert at 80–99% of limit (100%+ uses `expense`).
        static let warning     = Color(light: "#D08A2E", dark: "#E0A24E")
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
}

// MARK: - Typography Helpers

extension Font {
    /// Serif face (New York via .serif design, Georgia is the system fallback).
    /// Use for balance figures, card titles, and large headings.
    static func appSerif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// SF Pro system sans — body text, labels, buttons.
    static func appSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
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
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
    }
}

extension View {
    /// Applies the standard surface card treatment (background, radius, border).
    func cardStyle(padding: CGFloat = AppTheme.Spacing.md) -> some View {
        modifier(CardStyle(padding: padding))
    }
}
