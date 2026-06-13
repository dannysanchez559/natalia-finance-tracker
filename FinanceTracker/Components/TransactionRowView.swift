//
//  TransactionRowView.swift
//  Finna
//
//  Single transaction row in the new pastel + SF Symbol language: an IconBadge
//  on the left (category symbol on its pastel tint), the category label with the
//  wallet name beneath, and the signed amount on the right. The row is
//  transparent — it inherits its parent's background. Swipe actions and the
//  repeat-to-quick-action button live at the call sites, not here.
//

import SwiftUI

struct TransactionRowView: View {
    @Environment(DataStore.self) private var store

    var transaction: Transaction
    var category: AppCategory?
    var wallet: Wallet?

    private var isIncome: Bool { transaction.type == "income" }

    private var pastel: PastelStyle {
        IconMap.pastel(forCategory: category?.id ?? transaction.categoryId)
    }

    private var symbol: String {
        IconMap.symbol(forCategory: category?.id ?? transaction.categoryId)
    }

    private var amountText: String {
        let sign = isIncome ? "+" : "-"
        return sign + store.formatAmount(transaction.amount, code: transaction.currencyCode)
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            IconBadge(symbol: symbol, style: pastel, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(category?.label ?? "Uncategorized")
                    .font(.appSans(AppTheme.Typography.fontBody, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                if let name = wallet?.name {
                    Text(name)
                        .font(.appSans(AppTheme.Typography.fontLabel, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.textMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(amountText)
                .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                .foregroundStyle(isIncome ? AppTheme.Colors.income : AppTheme.Colors.expense)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    let cat = AppCategory(id: "cat-food", label: "Food", emoji: "🍕", colorHex: "#E07060")
    let wallet = Wallet(id: "wallet-cash", name: "Cash", emoji: "💵")
    return TransactionRowView(
        transaction: Transaction(amount: 12.5, categoryId: "cat-food", walletId: "wallet-cash", note: "Coffee"),
        category: cat,
        wallet: wallet
    )
    .environment(DataStore())
    .padding()
    .background(AppTheme.Colors.background)
}
