//
//  PastelCard.swift
//  Finna
//
//  The core pastel card look — a soft tinted fill with no shadow and no
//  border. Used for accounts and budgets. Apply with `.pastelCard(_:)`.
//

import SwiftUI

struct PastelCard: ViewModifier {
    var style: PastelStyle

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(style.fill)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

extension View {
    /// Styles a view as a pastel card: pastel fill, 18pt radius, 16pt padding,
    /// no shadow, no border.
    func pastelCard(_ style: PastelStyle) -> some View {
        modifier(PastelCard(style: style))
    }
}

#Preview {
    VStack(spacing: 12) {
        Text("Peach card")
            .frame(maxWidth: .infinity, alignment: .leading)
            .pastelCard(.peach)
        Text("Sky card")
            .frame(maxWidth: .infinity, alignment: .leading)
            .pastelCard(.sky)
    }
    .padding()
    .background(AppTheme.Colors.background)
}
