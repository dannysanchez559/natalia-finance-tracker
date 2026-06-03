//
//  TransactionRowView.swift
//  Finna
//
//  Single transaction row: category emoji in a colored circle, category
//  name, a "wallet · note" subtitle, and the signed amount. The parent
//  resolves the category and wallet so rows don't each run a query.
//

import SwiftUI

struct TransactionRowView: View {
    @Environment(DataStore.self) private var store

    var transaction: Transaction
    var category: AppCategory?
    var wallet: Wallet?

    private var isIncome: Bool { transaction.type == "income" }

    private var subtitle: String {
        let parts = [wallet?.name, transaction.note.isEmpty ? nil : transaction.note]
            .compactMap { $0 }
        return parts.joined(separator: " · ")
    }

    private var amountText: String {
        let sign = isIncome ? "+" : "-"
        return sign + store.formatAmount(transaction.amount, code: transaction.currencyCode)
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color(hex: category?.colorHex ?? "#8A7A66").opacity(0.18))
                Text(category?.emoji ?? "📌")
                    .font(.system(size: 18))
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(category?.label ?? "Uncategorized")
                    .font(.appSans(16, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.appSans(13))
                        .foregroundStyle(AppTheme.Colors.textMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(amountText)
                .font(.appSerif(16, weight: .medium))
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
