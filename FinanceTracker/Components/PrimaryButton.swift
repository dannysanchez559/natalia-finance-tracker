//
//  PrimaryButton.swift
//  Finna
//
//  Full-width accent call-to-action button. (Stub — refined in Phase 5.)
//

import SwiftUI

struct PrimaryButton: View {
    var title: String
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.appSans(17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

#Preview {
    PrimaryButton(title: "Save", action: {})
        .padding()
        .background(AppTheme.Colors.background)
}
