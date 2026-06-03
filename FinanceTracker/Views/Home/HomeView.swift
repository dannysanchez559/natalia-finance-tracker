//
//  HomeView.swift
//  Finna
//
//  Dashboard — the most visible screen. Header with month/year + settings,
//  active-trip banner, balance card (this month, currency selector,
//  month-over-month change, income/expense split), wallets row (all-time
//  balances), budget alert banners, recent transactions (last 3 days), and
//  a quick-add strip. All data is read from SwiftData and derived in place.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Wallet.name) private var wallets: [Wallet]
    @Query private var categories: [AppCategory]
    @Query private var trips: [Trip]

    @State private var editingTransaction: Transaction?
    @State private var showingSettings = false

    // UserDefaults-backed settings are not @Observable, so mirror them in
    // local state (loaded in onAppear, written through on mutation) to keep
    // the view in sync when they change.
    @State private var currencyCode = "USD"
    @State private var activeTripId: String?
    @State private var quickActions: [QuickAction] = []
    @State private var budgetLimits: [String: Double] = [:]

    // Fast lookups for resolving a transaction's category/wallet in rows.
    private var categoryById: [String: AppCategory] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }
    private var walletById: [String: Wallet] {
        Dictionary(uniqueKeysWithValues: wallets.map { ($0.id, $0) })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    header
                    if let trip = activeTrip { tripBanner(trip) }
                    balanceCard
                    walletsSection
                    if !budgetAlerts.isEmpty { budgetSection }
                    recentSection
                    if !quickActions.isEmpty { quickAddSection }
                }
                .padding(AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                // Clears the floating + button (56pt) and the tab bar.
                Color.clear.frame(height: 80)
            }
            .sheet(item: $editingTransaction) { tx in
                AddTransactionView(editing: tx)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear(perform: loadSettings)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(monthTitle)
                .font(.appSerif(28, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Spacer()
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
        }
    }

    private var monthTitle: String {
        Date.now.formatted(.dateTime.month(.wide).year())
    }

    // MARK: - Active Trip Banner

    private var activeTrip: Trip? {
        guard let id = activeTripId else { return nil }
        return trips.first { $0.id == id }
    }

    private func tripBanner(_ trip: Trip) -> some View {
        Button {
            activeTripId = nil
            store.activeTripId = nil
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "airplane")
                VStack(alignment: .leading, spacing: 1) {
                    Text("Active trip")
                        .font(.appSans(11, weight: .semibold))
                        .opacity(0.85)
                    Text(trip.name)
                        .font(.appSans(15, weight: .semibold))
                }
                Spacer()
                Text("Tap to end")
                    .font(.appSans(12, weight: .medium))
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.teal)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Balance Card

    private var monthTransactions: [Transaction] { transactions.inMonth() }

    private var lastMonthTransactions: [Transaction] {
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
        return transactions.inMonth(of: lastMonth)
    }

    /// Month-over-month change in expenses. `nil` when there's no prior-month
    /// spending to compare against. `isUp` means spending increased.
    private var spendingChange: (percent: Double, isUp: Bool)? {
        let current = monthTransactions.expenseTotal
        let previous = lastMonthTransactions.expenseTotal
        guard previous > 0 else { return nil }
        let pct = (current - previous) / previous * 100
        return (abs(pct), pct >= 0)
    }

    private var balanceCard: some View {
        let income = monthTransactions.incomeTotal
        let expense = monthTransactions.expenseTotal
        let net = income - expense

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("This Month")
                    .font(.appSans(12, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textMuted)
                Spacer()
                currencyButton
            }

            Text(store.formatAmount(net))
                .font(.appSerif(40, weight: .semibold))
                .foregroundStyle(net >= 0 ? AppTheme.Colors.income : AppTheme.Colors.expense)

            if let change = spendingChange {
                spendingChangeRow(change)
            }

            Divider()

            HStack(spacing: AppTheme.Spacing.lg) {
                totalColumn(title: "Income", amount: income, color: AppTheme.Colors.income)
                totalColumn(title: "Expenses", amount: expense, color: AppTheme.Colors.expense)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var currencyButton: some View {
        Button(action: cycleCurrency) {
            HStack(spacing: 4) {
                Text(currencyCode)
                    .font(.appSans(13, weight: .semibold))
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(AppTheme.Colors.accent)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, 5)
            .background(AppTheme.Colors.accent.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func spendingChangeRow(_ change: (percent: Double, isUp: Bool)) -> some View {
        HStack(spacing: 4) {
            Image(systemName: change.isUp ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 11, weight: .bold))
            Text(String(format: "%.0f%% vs last month", change.percent))
                .font(.appSans(13, weight: .medium))
        }
        .foregroundStyle(change.isUp ? AppTheme.Colors.expense : AppTheme.Colors.income)
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Wallets

    private var walletsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionHeader("Wallets") {
                Button("Edit") {
                    // TODO: Phase 4 — present wallet management sheet.
                }
                .font(.appSans(13, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accent)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(wallets) { wallet in
                        walletCard(wallet)
                    }
                }
                .padding(.horizontal, 1) // keeps the stroke from clipping
            }
        }
    }

    private func walletCard(_ wallet: Wallet) -> some View {
        let balance = transactions.balance(forWallet: wallet.id)
        return Button {
            // TODO: Phase 4 — present edit/delete sheet for this wallet.
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
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
        .buttonStyle(.plain)
    }

    // MARK: - Budget Alerts

    /// A category at 80%+ of its monthly limit. Orange 80–99%, red 100%+.
    private struct BudgetAlert: Identifiable {
        let category: AppCategory
        let spent: Double
        let limit: Double
        var id: String { category.id }
        var ratio: Double { limit > 0 ? spent / limit : 0 }
        var isOver: Bool { ratio >= 1 }
    }

    private var budgetAlerts: [BudgetAlert] {
        categories
            .filter { $0.type == "expense" }
            .compactMap { category -> BudgetAlert? in
                guard let limit = budgetLimits[category.id], limit > 0 else { return nil }
                let spent = monthTransactions
                    .filter { $0.categoryId == category.id && $0.type == "expense" }
                    .reduce(0) { $0 + $1.amount }
                guard spent >= limit * 0.8 else { return nil }
                return BudgetAlert(category: category, spent: spent, limit: limit)
            }
    }

    private var budgetSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(budgetAlerts) { alert in
                budgetBanner(alert)
            }
        }
    }

    private func budgetBanner(_ alert: BudgetAlert) -> some View {
        let color = alert.isOver ? AppTheme.Colors.expense : AppTheme.Colors.warning
        return HStack(spacing: AppTheme.Spacing.sm) {
            Text(alert.category.emoji)
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 1) {
                Text(alert.category.label)
                    .font(.appSans(14, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text("\(store.formatAmount(alert.spent)) of \(store.formatAmount(alert.limit))")
                    .font(.appSans(12))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
            Spacer()
            Text(String(format: "%.0f%%", alert.ratio * 100))
                .font(.appSans(15, weight: .bold))
                .foregroundStyle(color)
        }
        .padding(AppTheme.Spacing.md)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                .stroke(color.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Recent Transactions

    /// Day-groups for transactions in the last 3 calendar days (today + 2).
    private var recentGroups: [DayGroup] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: .now)) ?? .now
        let recent = transactions.filter { $0.date >= cutoff }
        return TransactionGrouping.byDay(recent)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionHeader("Recent") { EmptyView() }

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

            VStack(spacing: AppTheme.Spacing.xs) {
                ForEach(group.transactions) { tx in
                    recentRow(tx)
                }
            }
            .cardStyle()
        }
    }

    private func recentRow(_ tx: Transaction) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Button { editingTransaction = tx } label: {
                TransactionRowView(
                    transaction: tx,
                    category: categoryById[tx.categoryId],
                    wallet: walletById[tx.walletId]
                )
            }
            .buttonStyle(.plain)

            Button { saveAsQuickAction(tx) } label: {
                Image(systemName: "repeat")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
            .buttonStyle(.plain)
            .disabled(quickActions.count >= 6)
            .opacity(quickActions.count >= 6 ? 0.3 : 1)

            Button { delete(tx) } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.expense)
            }
            .buttonStyle(.plain)
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

    // MARK: - Quick Add

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionHeader("Quick Add") { EmptyView() }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(quickActions) { action in
                        quickAddChip(action)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private func quickAddChip(_ action: QuickAction) -> some View {
        let category = categoryById[action.categoryId]
        return HStack(spacing: AppTheme.Spacing.sm) {
            Button { runQuickAction(action) } label: {
                HStack(spacing: 6) {
                    Text(category?.emoji ?? "📌")
                    Text(store.formatAmount(action.amount))
                        .font(.appSans(14, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
            }
            .buttonStyle(.plain)

            Button { removeQuickAction(action) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.Colors.surface)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.Colors.border, lineWidth: 1))
    }

    // MARK: - Section Header Helper

    private func sectionHeader<Trailing: View>(
        _ title: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack {
            Text(title)
                .font(.appSans(12, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textMuted)
            Spacer()
            trailing()
        }
    }

    // MARK: - Actions

    private func loadSettings() {
        currencyCode = store.currencyCode
        activeTripId = store.activeTripId
        quickActions = store.quickActions
        budgetLimits = store.budgetLimits
    }

    private func cycleCurrency() {
        let codes = DataStore.currencies.map(\.code)
        let index = codes.firstIndex(of: currencyCode) ?? 0
        let next = codes[(index + 1) % codes.count]
        currencyCode = next
        store.currencyCode = next
    }

    private func delete(_ tx: Transaction) {
        modelContext.delete(tx)
        try? modelContext.save()
    }

    private func saveAsQuickAction(_ tx: Transaction) {
        guard quickActions.count < 6 else { return }
        let action = QuickAction(
            type: tx.type,
            amount: tx.amount,
            categoryId: tx.categoryId,
            walletId: tx.walletId,
            note: tx.note
        )
        var updated = quickActions
        updated.append(action)
        quickActions = updated
        store.quickActions = updated
    }

    private func removeQuickAction(_ action: QuickAction) {
        let updated = quickActions.filter { $0.id != action.id }
        quickActions = updated
        store.quickActions = updated
    }

    private func runQuickAction(_ action: QuickAction) {
        // Auto-tag to the active trip for expenses only.
        let tripId = (action.type == "expense") ? activeTripId : nil
        let tx = Transaction(
            type: action.type,
            amount: action.amount,
            currencyCode: store.currencyCode,
            categoryId: action.categoryId,
            walletId: action.walletId,
            note: action.note,
            tripId: tripId,
            date: .now
        )
        modelContext.insert(tx)
        try? modelContext.save()
    }
}

#Preview {
    HomeView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
