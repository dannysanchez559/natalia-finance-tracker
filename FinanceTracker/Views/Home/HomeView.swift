//
//  HomeView.swift
//  Finna
//
//  Dashboard — the most visible screen. Ofspace-inspired layout: greeting
//  header with avatar, a bold hero balance card (this month, income/expense
//  split), a horizontal Accounts strip (all-time wallet balances), a budgets
//  card with progress bars, and recent transactions (last 3 days). All data is
//  read from SwiftData and derived in place.
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
    @State private var showingBudgetManager = false
    @State private var showingSearch = false
    @State private var showingAllTransactions = false

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
                    budgetSection
                    recentSection
                    if !quickActions.isEmpty { quickAddSection }
                }
                .padding(AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                // Clears the floating + button (56pt) and the tab bar.
                Color.clear.frame(height: 100)
            }
            .sheet(item: $editingTransaction) { tx in
                AddTransactionView(editing: tx)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingBudgetManager) {
                BudgetManagerView()
            }
            .sheet(isPresented: $showingSearch) {
                SearchView()
            }
            .sheet(isPresented: $showingAllTransactions) {
                AllTransactionsView()
            }
            .onAppear(perform: loadSettings)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Good morning")
                    .font(.appSans(AppTheme.Typography.fontCaption, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textMuted)
                Text(monthTitle)
                    .font(.appSans(AppTheme.Typography.fontTitle, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            Spacer()
            HStack(spacing: AppTheme.Spacing.md) {
                Button {
                    showingSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.textMuted)
                }
                Button {
                    showingSettings = true
                } label: {
                    Text("F")
                        .font(.appSans(16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.Colors.accent)
                        .clipShape(Circle())
                }
            }
            .buttonStyle(.plain)
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

    // MARK: - Hero Balance Card

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
                Text("Working balance")
                    .font(.appSans(AppTheme.Typography.fontCaption, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                currencyButton
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(store.formatAmount(net))
                    .font(.appSans(AppTheme.Typography.fontBalance, weight: .thin))
                    .tracking(AppTheme.Typography.trackingTight)
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.3), value: net)
                Text(monthTitle)
                    .font(.appSans(AppTheme.Typography.fontCaption, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                heroInnerCard(title: "Income", amount: income)
                heroInnerCard(title: "Expenses", amount: expense)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.heroCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
        .shadow(color: AppTheme.Colors.heroCard.opacity(0.35), radius: 16, x: 0, y: 8)
    }

    private func heroInnerCard(title: String, amount: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.appSans(AppTheme.Typography.fontCaption, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            Text(store.formatAmount(amount))
                .font(.appSans(AppTheme.Typography.fontCardNumber, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
    }

    private var currencyButton: some View {
        Button(action: cycleCurrency) {
            HStack(spacing: 4) {
                Text(currencyCode)
                    .font(.appSans(13, weight: .semibold))
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.15))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Accounts

    private var walletsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionHeader("Accounts") {
                Button("Edit") {
                    // TODO: Phase 4 — present wallet management sheet.
                }
                .font(.appSans(AppTheme.Typography.fontLabel, weight: .medium))
                .foregroundStyle(AppTheme.Colors.accent)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(wallets) { wallet in
                        walletCard(wallet)
                    }
                }
                .padding(.horizontal, 2) // keeps the shadow from clipping
                .padding(.vertical, 4)
            }
        }
    }

    private func walletCard(_ wallet: Wallet) -> some View {
        let balance = transactions.balance(forWallet: wallet.id)
        return Button {
            // TODO: Phase 4 — present edit/delete sheet for this wallet.
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Full-width color bar; top corners are rounded by the outer clip.
                Rectangle()
                    .fill(Color(hex: wallet.colorHex))
                    .frame(height: 3)

                VStack(alignment: .leading, spacing: 6) {
                    Text(wallet.emoji)
                        .font(.system(size: 20))
                    Text(wallet.name)
                        .font(.appSans(AppTheme.Typography.fontCaption, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.textMuted)
                        .lineLimit(1)
                    Text(store.formatAmount(balance))
                        .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 100)
            .background(AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Budgets

    /// An expense category with a monthly limit set, plus its month-to-date spend.
    private struct BudgetItem: Identifiable {
        let category: AppCategory
        let spent: Double
        let limit: Double
        var id: String { category.id }
        var ratio: Double { limit > 0 ? spent / limit : 0 }
    }

    private var budgetItems: [BudgetItem] {
        categories
            .filter { $0.type == "expense" }
            .compactMap { category -> BudgetItem? in
                guard let limit = budgetLimits[category.id], limit > 0 else { return nil }
                let spent = monthTransactions
                    .filter { $0.categoryId == category.id && $0.type == "expense" }
                    .reduce(0) { $0 + $1.amount }
                return BudgetItem(category: category, spent: spent, limit: limit)
            }
    }

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionHeader("Your budgets") {
                Button("Manage") {
                    showingBudgetManager = true
                }
                .font(.appSans(AppTheme.Typography.fontLabel, weight: .medium))
                .foregroundStyle(AppTheme.Colors.accent)
            }

            budgetCard
        }
    }

    private var budgetCard: some View {
        VStack(spacing: 0) {
            if budgetItems.isEmpty {
                Text("Tap Manage to set spending limits")
                    .font(.appSans(AppTheme.Typography.fontLabel, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppTheme.Spacing.sm)
            } else {
                ForEach(Array(budgetItems.enumerated()), id: \.element.id) { index, item in
                    budgetRow(item)
                    if index < budgetItems.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }

    private func budgetRow(_ item: BudgetItem) -> some View {
        let fillColor: Color = {
            if item.ratio >= 1 { return AppTheme.Colors.expense }
            if item.ratio >= 0.8 { return Color(hex: "#E0924A") }
            return AppTheme.Colors.accent
        }()

        return VStack(spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Text(item.category.emoji)
                    .font(.system(size: 18))
                Text(item.category.label)
                    .font(.appSans(AppTheme.Typography.fontBody, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
                Text("\(store.formatAmount(item.spent)) / \(store.formatAmount(item.limit))")
                    .font(.appSans(AppTheme.Typography.fontLabel, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.Colors.borderAlt)
                    Capsule()
                        .fill(fillColor)
                        .frame(width: geo.size.width * min(item.ratio, 1))
                }
            }
            .frame(height: 5)
        }
        .padding(.vertical, AppTheme.Spacing.sm)
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
            sectionHeader("Recent") {
                Button("See all") {
                    showingAllTransactions = true
                }
                .font(.appSans(AppTheme.Typography.fontLabel, weight: .medium))
                .foregroundStyle(AppTheme.Colors.accent)
            }

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
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    // MARK: - Section Header Helper

    private func sectionHeader<Trailing: View>(
        _ title: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack {
            Text(title)
                .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
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
