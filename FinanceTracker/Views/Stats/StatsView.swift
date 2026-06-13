//
//  StatsView.swift
//  Finna
//
//  Spending breakdown + budgets. A Week/Month/Year picker drives every figure
//  below it: a donut chart of expenses by category (with a center total and a
//  sorted legend) and a budgets card showing per-category progress against the
//  limits set in BudgetManagerView. All values are derived from a single
//  @Query of every transaction, filtered in computed properties.
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(DataStore.self) private var store

    @Query private var transactions: [Transaction]
    @Query private var categories: [AppCategory]

    @State private var period: Period = .month
    @State private var showingBudgetManager = false

    // UserDefaults-backed budgets aren't @Observable; mirror in local state,
    // reloaded whenever the manager sheet dismisses.
    @State private var budgetLimits: [String: Double] = [:]

    // Drives the budget bars filling from zero when the screen first appears.
    @State private var barsAppeared = false

    // MARK: - Period

    enum Period: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        var id: String { rawValue }
    }

    // MARK: - Derived Data

    private var expenseCategories: [AppCategory] {
        categories.filter { $0.type == "expense" }
    }

    private var categoryById: [String: AppCategory] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }

    /// Expense transactions inside the selected period.
    private var periodExpenses: [Transaction] {
        let calendar = Calendar.current
        let now = Date.now
        return transactions.filter { tx in
            guard tx.type == "expense" else { return false }
            switch period {
            case .week:
                guard let cutoff = calendar.date(byAdding: .day, value: -7, to: now) else { return false }
                return tx.date >= cutoff && tx.date <= now
            case .month:
                return calendar.isDate(tx.date, equalTo: now, toGranularity: .month)
            case .year:
                return calendar.isDate(tx.date, equalTo: now, toGranularity: .year)
            }
        }
    }

    /// One slice per category that has spending in the period, largest first.
    private var slices: [CategorySlice] {
        let totals = Dictionary(grouping: periodExpenses, by: \.categoryId)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }

        return totals
            .compactMap { categoryId, amount -> CategorySlice? in
                guard amount > 0, let category = categoryById[categoryId] else { return nil }
                return CategorySlice(category: category, amount: amount)
            }
            .sorted { $0.amount > $1.amount }
    }

    private var totalSpent: Double {
        periodExpenses.reduce(0) { $0 + $1.amount }
    }

    /// Slices paired with a color from the curated blue-purple palette, assigned
    /// in amount-descending order. Drives both the donut and the legend so they
    /// stay in sync.
    private var coloredSlices: [ColoredSlice] {
        slices.enumerated().map { index, slice in
            ColoredSlice(
                slice: slice,
                color: AppTheme.Colors.chartPalette[index % AppTheme.Colors.chartPalette.count]
            )
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    periodPicker
                    breakdownCard
                    budgetsCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Stats")
                        .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Clears the floating + button (56pt) and the tab bar.
                Color.clear.frame(height: 100)
            }
            .sheet(isPresented: $showingBudgetManager, onDismiss: loadBudgets) {
                BudgetManagerView()
            }
            .onAppear {
                loadBudgets()
                barsAppeared = false
                withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                    barsAppeared = true
                }
            }
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("Period", selection: $period) {
            ForEach(Period.allCases) { p in
                Text(p.rawValue).tag(p)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Spending Breakdown

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Spending")
                .font(.appSans(AppTheme.Typography.fontLabel, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accent)

            if slices.isEmpty {
                breakdownEmptyState
            } else {
                donut
                legend
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: AppTheme.Spacing.md)
    }

    private var donut: some View {
        Chart(coloredSlices) { item in
            SectorMark(
                angle: .value("Amount", item.slice.amount),
                innerRadius: .ratio(0.62),
                angularInset: 1.5
            )
            .cornerRadius(3)
            .foregroundStyle(item.color)
        }
        .frame(height: 200)
        .chartBackground { _ in
            VStack(spacing: 2) {
                Text("Total")
                    .font(.appSans(AppTheme.Typography.fontCaption, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Text(store.formatAmount(totalSpent))
                    .font(.appSans(AppTheme.Typography.fontBalance, weight: .thin))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .tracking(AppTheme.Typography.trackingTight)
            }
        }
    }

    private var legend: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(coloredSlices) { item in
                legendRow(item.slice, color: item.color)
            }
        }
    }

    private func legendRow(_ slice: CategorySlice, color: Color) -> some View {
        let percent = totalSpent > 0 ? slice.amount / totalSpent * 100 : 0
        return HStack(spacing: AppTheme.Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            IconBadge(
                symbol: IconMap.symbol(forCategory: slice.category.id),
                style: IconMap.pastel(forCategory: slice.category.id),
                size: 28
            )
            Text(slice.category.label)
                .font(.appSans(AppTheme.Typography.fontBody, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Text(String(format: "%.0f%%", percent))
                .font(.appSans(AppTheme.Typography.fontLabel, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textMuted)

            Spacer()

            Text(store.formatAmount(slice.amount))
                .font(.appSans(AppTheme.Typography.fontCardNumber, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.expense)
        }
    }

    private var breakdownEmptyState: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.Colors.textMuted.opacity(0.5))
            Text("No spending data yet")
                .font(.appSans(16))
                .foregroundStyle(AppTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Budgets

    /// Categories that have a budget set, paired with their period spend.
    private var budgetRows: [BudgetRow] {
        expenseCategories.compactMap { category -> BudgetRow? in
            guard let limit = budgetLimits[category.id], limit > 0 else { return nil }
            let spent = periodExpenses
                .filter { $0.categoryId == category.id }
                .reduce(0) { $0 + $1.amount }
            return BudgetRow(category: category, spent: spent, limit: limit)
        }
        .sorted { $0.ratio > $1.ratio }
    }

    private var budgetsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Budgets")
                    .font(.appSans(AppTheme.Typography.fontLabel, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
                Spacer()
                Button("Manage") { showingBudgetManager = true }
                    .font(.appSans(13, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
            }

            if budgetRows.isEmpty {
                Text("Tap Manage to set spending limits")
                    .font(.appSans(AppTheme.Typography.fontBody))
                    .foregroundStyle(AppTheme.Colors.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(budgetRows) { row in
                    budgetRowView(row)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: AppTheme.Spacing.md)
    }

    private func budgetRowView(_ row: BudgetRow) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                IconBadge(
                    symbol: IconMap.symbol(forCategory: row.category.id),
                    style: IconMap.pastel(forCategory: row.category.id),
                    size: 28
                )
                Text(row.category.label)
                    .font(.appSans(AppTheme.Typography.fontBody, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
                Text("\(store.formatAmount(row.spent)) / \(store.formatAmount(row.limit))")
                    .font(.appSans(AppTheme.Typography.fontLabel, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }

            progressBar(ratio: row.ratio, color: row.color)
        }
    }

    private func progressBar(ratio: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.Colors.border)
                Capsule()
                    .fill(color)
                    .frame(width: (barsAppeared ? max(0, min(ratio, 1)) : 0) * geo.size.width)
            }
        }
        .frame(height: 8)
    }

    // MARK: - Actions

    private func loadBudgets() {
        budgetLimits = store.budgetLimits
    }
}

// MARK: - Row Models

private struct CategorySlice: Identifiable {
    let category: AppCategory
    let amount: Double
    var id: String { category.id }
}

/// A slice paired with its assigned palette color (shared by donut + legend).
private struct ColoredSlice: Identifiable {
    let slice: CategorySlice
    let color: Color
    var id: String { slice.id }
}

private struct BudgetRow: Identifiable {
    let category: AppCategory
    let spent: Double
    let limit: Double
    var id: String { category.id }
    var ratio: Double { limit > 0 ? spent / limit : 0 }

    /// Accent under 80%, orange 80–99%, expense red at 100%+.
    var color: Color {
        if ratio >= 1 { return AppTheme.Colors.expense }
        if ratio >= 0.8 { return AppTheme.Colors.warning }
        return AppTheme.Colors.accent
    }
}

#Preview {
    StatsView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
