//
//  IconBadge.swift
//  Finna
//
//  Reusable rounded-square icon badge. Replaces emoji circles everywhere —
//  renders an SF Symbol on a pastel badge fill. Used by transaction rows,
//  account cards, budget cards, and anywhere an item needs an icon chip.
//

import SwiftUI

struct IconBadge: View {
    /// SF Symbol name to render (see `IconMap`).
    var symbol: String
    /// Pastel theme — `badge` is the fill, `text` is the symbol color.
    var style: PastelStyle
    /// Edge length of the badge. The symbol is ~45% of this.
    var size: CGFloat = 44

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(style.badge)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundStyle(style.text)
            }
    }
}

#Preview {
    HStack(spacing: 12) {
        IconBadge(symbol: "fork.knife", style: .peach)
        IconBadge(symbol: "creditcard.fill", style: .sky, size: 36)
        IconBadge(symbol: "airplane", style: .lavender, size: 56)
    }
    .padding()
    .background(AppTheme.Colors.background)
}
