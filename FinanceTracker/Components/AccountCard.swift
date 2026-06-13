//
//  AccountCard.swift
//  Finna
//
//  A pastel tile for the Accounts horizontal scroll: a wallet icon badge at the
//  top, the wallet's all-time balance and name pushed to the bottom. The pastel
//  is chosen by the wallet's position in the list (index). Balance is computed
//  at the call site and passed in.
//

import SwiftUI

struct AccountCard: View {
    @Environment(DataStore.self) private var store

    var wallet: Wallet
    var balance: Double
    var index: Int

    private var pastel: PastelStyle { IconMap.pastel(forIndex: index) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            IconBadge(symbol: IconMap.symbol(forWallet: wallet.id), style: pastel, size: 36)

            Spacer(minLength: AppTheme.Spacing.sm)

            Text(store.formatAmount(balance))
                .font(.appSans(AppTheme.Typography.fontCardNumber, weight: .semibold))
                .foregroundStyle(pastel.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(wallet.name)
                .font(.appSans(AppTheme.Typography.fontLabel, weight: .medium))
                .foregroundStyle(pastel.text.opacity(0.8))
                .lineLimit(1)
        }
        .padding(16)
        .frame(width: 150, height: 110, alignment: .topLeading)
        .background(pastel.fill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    HStack(spacing: 12) {
        AccountCard(wallet: Wallet(id: "wallet-cash", name: "Cash", emoji: "💵"), balance: 1240.50, index: 0)
        AccountCard(wallet: Wallet(id: "wallet-card", name: "Card", emoji: "💳"), balance: 320, index: 1)
    }
    .environment(DataStore())
    .padding()
    .background(AppTheme.Colors.background)
}
