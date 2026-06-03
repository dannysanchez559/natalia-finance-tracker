//
//  HomeView.swift
//  Finna
//
//  Dashboard. Shows this month's balance/income/expenses, a horizontal
//  row of wallets with all-time balances, and the most recent days of
//  transactions. Tapping a transaction opens it for editing.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(DataStore.self) private var store

    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Wallet.name) private var wallets: [Wallet]
    @Query private var categories: [AppCategory]

    @State private var editingTransaction: Transaction?

    // Fast lookups for resolving a transaction's category/wallet in rows.
    private var categoryById: [String: AppCategory] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }
    private var walletById: [String: Wallet] {
        Dictionary(uniqueKeysWithValues: wallets.map { ($0.id, $0) })
    }

    private var monthTransactions: [Transaction] { transactions.inMonth() }

    /// First three day-groups of history (matches the prototype's "Recent").
    private var recentGroups: [DayGroup] {
        Array(TransactionGrouping.byDay(transactions).prefix(3))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    balanceCard
                    walletsSection
                    recentSection
                }
                .padding(AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle(monthTitle)
            .sheet(item: $editingTransaction) { tx in
                AddTransactionView(editing: tx)
            }
        }
    }

    private var monthTitle: String {
        Date.now.formatted(.dateTime.month(.wide).year())
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        let income = monthTransactions.incomeTotal
        let expense = monthTransactions.expenseTotal
        let net = income - expense

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("This Month")
                .font(.appSans(12, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textMuted)

            Text(store.formatAmount(net))
                .font(.appSerif(40, weight: .semibold))
                .foregroundStyle(net >= 0 ? AppTheme.Colors.textPrimary : AppTheme.Colors.expense)

            HStack(spacing: AppTheme.Spacing.lg) {
                totalColumn(title: "Income", amount: income, color: AppTheme.Colors.income)
                totalColumn(title: "Expenses", amount: expense, color: AppTheme.Colors.expense)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func totalColumn(title: String, amount: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.appSans(12))
                .foregroundStyle(AppTheme.Colors.textMuted)
            Text(store.formatAmount(amount))
                .font(.appSans(17, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    // MARK: - Wallets

    private var walletsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Wallets")
                .font(.appSans(12, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textMuted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(wallets) { wallet in
                        walletCard(wallet)
                    }
                }
            }
        }
    }

    private func walletCard(_ wallet: Wallet) -> some View {
        let balance = transactions.balance(forWallet: wallet.id)
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(wallet.emoji)
                .font(.system(size: 22))
            Text(wallet.name)
                .font(.appSans(13, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textMuted)
            Text(store.formatAmount(balance))
                .font(.appSerif(18, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .frame(width: 130, alignment: .leading)
        .cardStyle()
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(hex: wallet.colorHex))
                .frame(height: 3)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
        }
    }

    // MARK: - Recent Transactions

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Recent")
                .font(.appSans(12, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textMuted)

            if recentGroups.isEmpty {
                emptyState
            } else {
                ForEach(recentGroups) { group in
                    dayGroup(group)
                }
            }
        }
    }

    private func dayGroup(_ group: DayGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(group.label)
                .font(.appSans(13, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding(.vertical, AppTheme.Spacing.sm)

            VStack(spacing: 0) {
                ForEach(group.transactions) { tx in
                    Button { editingTransaction = tx } label: {
                        TransactionRowView(
                            transaction: tx,
                            category: categoryById[tx.categoryId],
                            wallet: walletById[tx.walletId]
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .cardStyle()
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "wallet.bifold")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.Colors.textMuted.opacity(0.5))
            Text("No entries yet")
                .font(.appSerif(16))
                .foregroundStyle(AppTheme.Colors.textMuted)
            Text("Tap + to add your first record")
                .font(.appSans(13))
                .foregroundStyle(AppTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    HomeView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
