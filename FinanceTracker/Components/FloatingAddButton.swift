//
//  FloatingAddButton.swift
//  Finna
//
//  56pt accent-colored circle with a plus icon. Fixed above the tab bar.
//

import SwiftUI

struct FloatingAddButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.appSans(24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(AppTheme.Colors.accent)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel("Add transaction")
    }
}

#Preview {
    FloatingAddButton(action: {})
}
