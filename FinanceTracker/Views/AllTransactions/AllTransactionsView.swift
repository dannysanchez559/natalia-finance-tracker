//
//  AllTransactionsView.swift
//  Finna
//
//  Complete transaction history, newest first, grouped by day. Tap a row
//  to edit; swipe to edit (leading) or delete (trailing).
//

import SwiftUI
import SwiftData

struct AllTransactionsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var wallets: [Wallet]
    @Query private var categories: [AppCategory]

    @State private var editingTransaction: Transaction?

    private var categoryById: [String: AppCategory] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }
    private var walletById: [String: Wallet] {
        Dictionary(uniqueKeysWithValues: wallets.map { ($0.id, $0) })
    }

    private var groups: [DayGroup] { TransactionGrouping.byDay(transactions) }

    var body: some View {
        NavigationStack {
            Group {
                if groups.isEmpty {
                    emptyState
                } else {
                    transactionList
                }
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("All")
            .sheet(item: $editingTransaction) { tx in
                AddTransactionView(editing: tx)
            }
        }
    }

    private var transactionList: some View {
        List {
            ForEach(groups) { group in
                Section {
                    ForEach(group.transactions) { tx in
                        TransactionRowView(
                            transaction: tx,
                            category: categoryById[tx.categoryId],
                            wallet: walletById[tx.walletId]
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { editingTransaction = tx }
                        .listRowBackground(AppTheme.Colors.surface)
                        .swipeActions(edge: .leading) {
                            Button { editingTransaction = tx } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(AppTheme.Colors.accent)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { delete(tx) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text(group.label)
                        .font(.appSans(13, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.Colors.textMuted.opacity(0.5))
            Text("No transactions yet")
                .font(.appSerif(16))
                .foregroundStyle(AppTheme.Colors.textMuted)
            Text("Tap + to add your first record")
                .font(.appSans(13))
                .foregroundStyle(AppTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func delete(_ tx: Transaction) {
        modelContext.delete(tx)
        try? modelContext.save()
    }
}

#Preview {
    AllTransactionsView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
