//
//  OnboardingView.swift
//  Finna
//
//  First-launch intro. A 4-screen paged walkthrough with a custom dot
//  indicator and CTA. Completing it sets hasOnboarded = true upstream,
//  which flips ContentView over to MainTabView.
//

import SwiftUI

struct OnboardingView: View {
    /// Called when onboarding completes (sets hasOnboarded = true upstream).
    var onFinish: () -> Void

    @State private var currentPage = 0

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let pastel: PastelStyle
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(
            symbol: "target",
            pastel: .peach,
            title: "Take control of your money",
            body: "Track spending, set budgets, and reach your goals — all in one simple app."
        ),
        Page(
            symbol: "creditcard.fill",
            pastel: .sky,
            title: "All your wallets in one place",
            body: "Cash, card, savings — track each separately and see your total balance at a glance."
        ),
        Page(
            symbol: "airplane",
            pastel: .mint,
            title: "Built for life on the go",
            body: "Switch currencies anytime. Use Trip mode to tag expenses per journey automatically."
        ),
        Page(
            symbol: "lock.fill",
            pastel: .lavender,
            title: "Your data stays with you",
            body: "No accounts, no servers, no tracking. Everything lives on your device."
        ),
    ]

    private var isLastPage: Bool { currentPage == pages.count - 1 }

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        pageContent(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageIndicator

                ctaButton

                skipButton
                    .opacity(currentPage == 0 ? 0 : 1)
                    .disabled(currentPage == 0)
            }
            .padding(.bottom, AppTheme.Spacing.lg)
        }
    }

    // MARK: - Page Content

    private func pageContent(_ page: Page) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            IconBadge(symbol: page.symbol, style: page.pastel, size: 96)

            Text(page.title)
                .font(.appSans(AppTheme.Typography.fontTitle, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(page.body)
                .font(.appSans(AppTheme.Typography.fontBody))
                .foregroundStyle(AppTheme.Colors.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.lg)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Dot Indicator

    private var pageIndicator: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? AppTheme.Colors.accent : AppTheme.Colors.border)
                    .frame(width: index == currentPage ? 20 : 8, height: 8)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button {
            if isLastPage {
                onFinish()
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    currentPage += 1
                }
            }
        } label: {
            Text(isLastPage ? "Get Started" : "Continue")
                .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppTheme.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }

    private var skipButton: some View {
        Button("Skip") {
            onFinish()
        }
        .font(.appSans(AppTheme.Typography.fontLabel))
        .foregroundStyle(AppTheme.Colors.textMuted)
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
