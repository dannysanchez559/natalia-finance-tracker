//
//  TransactionRowView.swift
//  Finna
//
//  Single transaction row: category emoji, name, subtitle, amount.
//  (Stub — wired to real data and swipe actions in Phase 4.)
//

import SwiftUI

struct TransactionRowView: View {
    var transaction: Transaction

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Circle()
                .fill(AppTheme.Colors.border)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.note.isEmpty ? "Transaction" : transaction.note)
                    .font(.appSans(16, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(transaction.categoryId)
                    .font(.appSans(13))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }

            Spacer()

            Text(String(format: "%.2f", transaction.amount))
                .font(.appSerif(16, weight: .medium))
                .foregroundStyle(
                    transaction.type == "income"
                        ? AppTheme.Colors.income
                        : AppTheme.Colors.expense
                )
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TransactionRowView(transaction: Transaction(amount: 12.5, note: "Coffee"))
        .padding()
        .background(AppTheme.Colors.background)
}
