//
//  OnboardingView.swift
//  Finna
//
//  First-launch intro. Phase 3 skeleton — placeholder plus a dev skip button
//  that completes onboarding. Full 4-screen pager is built in a later phase.
//

import SwiftUI

struct OnboardingView: View {
    /// Called when onboarding completes (sets hasOnboarded = true upstream).
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                Spacer()

                Text("💰")
                    .font(.system(size: 72))

                Text("Finna")
                    .font(.appSerif(40, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text("Onboarding — placeholder")
                    .font(.appSans(15))
                    .foregroundStyle(AppTheme.Colors.textMuted)

                Spacer()

                // Dev skip — bypasses onboarding during Phase 2/3 development.
                PrimaryButton(title: "Skip (dev)") {
                    onFinish()
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.lg)
            }
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
