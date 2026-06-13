//
//  PlansView.swift
//  Finna
//
//  Phase 4 screen 6 — Plans. Four stacked sections, each with a header
//  (title + SF Symbol + Add) that presents its own form sheet:
//    1. Recurring       — RecurringRule records, frequency-driven auto-transactions
//    2. Trips           — one active trip at a time, budget progress
//    3. Savings Goals   — manual progress toward a target
//    4. Subscriptions   — monthly/yearly trackers with a monthly-total footer
//
//  All four sections live in a single ScrollView. Deletion uses a custom
//  swipe-to-reveal control (SwipeToDeleteContainer) so it works outside a List,
//  each delete gated behind a confirmation dialog.
//

import SwiftUI
import SwiftData

struct PlansView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    RecurringSection()
                    TripsSection()
                    SavingsGoalsSection()
                    SubscriptionsSection()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Plans")
                        .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Clears the floating + button (56pt) and the tab bar.
                Color.clear.frame(height: 100)
            }
        }
    }
}

// MARK: - Shared Building Blocks

/// Section header: a pastel IconBadge, the title, and a trailing circular Add
/// button (a consistent 32pt accent circle).
private struct PlanSectionHeader: View {
    let title: String
    let systemImage: String
    let pastel: PastelStyle
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            IconBadge(symbol: systemImage, style: pastel, size: 32)
            Text(title)
                .font(.appSans(AppTheme.Typography.fontTitle, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.Colors.accent)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
}

/// Returns `stored` when it is an SF Symbol name (ASCII), otherwise `fallback`.
/// Goals and subscriptions keep their icon in the legacy `emoji` field; new
/// records store an SF Symbol name there, while older records may still hold an
/// emoji — this renders both safely without a data migration.
private func planSymbol(_ stored: String, fallback: String) -> String {
    !stored.isEmpty && stored.allSatisfy(\.isASCII) ? stored : fallback
}

/// A pill badge — used for recurring frequency and subscription period.
private struct PlanBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.appSans(AppTheme.Typography.fontLabel, weight: .semibold))
            .foregroundStyle(AppTheme.Colors.accent)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, 3)
            .background(AppTheme.Colors.accent.opacity(0.15))
            .clipShape(Capsule())
    }
}

/// A thin progress bar with a configurable fill color. Fills from zero on
/// appear with a short eased animation, matching the Stats budget bars.
private struct PlanProgressBar: View {
    let ratio: Double
    let color: Color

    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(AppTheme.Colors.border)
                Capsule()
                    .fill(color)
                    .frame(width: (appeared ? max(0, min(ratio, 1)) : 0) * geo.size.width)
            }
        }
        .frame(height: 8)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                appeared = true
            }
        }
    }
}

/// An empty-state line shown when a section has no records yet.
private struct PlanEmptyRow: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.appSans(AppTheme.Typography.fontBody))
            .foregroundStyle(AppTheme.Colors.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppTheme.Spacing.sm)
    }
}

/// Wraps a whole section as a contained module: the header + Add button at the
/// top, a divider, then the section's content rows — all inside one surface
/// card. Each section supplies its header parameters and a content builder.
private struct PlanSectionCard<Content: View>: View {
    let title: String
    let systemImage: String
    let pastel: PastelStyle
    let onAdd: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PlanSectionHeader(title: title, systemImage: systemImage, pastel: pastel, onAdd: onAdd)
            Divider()
                .overlay(AppTheme.Colors.borderAlt)
                .padding(.vertical, AppTheme.Spacing.sm)
            content
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }
}

private extension View {
    /// Opaque surface treatment for an individual row inside a section card.
    /// The opacity is what masks the swipe-to-delete control until revealed.
    func planRow() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
    }
}

/// Wraps a row in a swipe-left-to-reveal delete control. Works outside of a
/// List (the whole screen is a ScrollView), and gates the delete behind a
/// confirmation dialog. The content supplies its own card background.
private struct SwipeToDeleteContainer<Content: View>: View {
    let confirmTitle: String
    let onDelete: () -> Void
    @ViewBuilder var content: Content

    @State private var offset: CGFloat = 0
    @State private var confirming = false
    private let buttonWidth: CGFloat = 76

    var body: some View {
        ZStack(alignment: .trailing) {
            Button { confirming = true } label: {
                Image(systemName: "trash")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: buttonWidth)
                    .frame(maxHeight: .infinity)
                    .background(AppTheme.Colors.expense)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
            }
            .buttonStyle(.plain)

            content
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { value in
                            // Only react to predominantly-horizontal drags so
                            // vertical scrolling still works.
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            if value.translation.width < 0 {
                                offset = max(value.translation.width, -buttonWidth)
                            } else {
                                offset = min(0, -buttonWidth + value.translation.width)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.easeOut(duration: 0.2)) {
                                offset = value.translation.width < -buttonWidth / 2 ? -buttonWidth : 0
                            }
                        }
                )
        }
        .confirmationDialog(confirmTitle, isPresented: $confirming, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                withAnimation { offset = 0 }
                onDelete()
            }
            Button("Cancel", role: .cancel) {
                withAnimation { offset = 0 }
            }
        }
    }
}

// MARK: - Section 1: Recurring

private struct RecurringSection: View {
    @Environment(DataStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \RecurringRule.note) private var rules: [RecurringRule]
    @Query private var categories: [AppCategory]

    @State private var showingForm = false

    private var categoryById: [String: AppCategory] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }

    var body: some View {
        PlanSectionCard(title: "Recurring", systemImage: "arrow.triangle.2.circlepath", pastel: .peach) {
            showingForm = true
        } content: {
            if rules.isEmpty {
                PlanEmptyRow(text: "No recurring rules yet")
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(rules) { rule in
                        SwipeToDeleteContainer(confirmTitle: "Delete this recurring rule?") {
                            delete(rule)
                        } content: {
                            ruleRow(rule)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            RecurringFormView()
        }
    }

    private func ruleRow(_ rule: RecurringRule) -> some View {
        let category = categoryById[rule.categoryId]
        let isIncome = rule.type == "income"
        let title = rule.note.isEmpty ? (category?.label ?? "Recurring") : rule.note
        return HStack(spacing: AppTheme.Spacing.md) {
            IconBadge(
                symbol: IconMap.symbol(forCategory: rule.categoryId),
                style: IconMap.pastel(forCategory: rule.categoryId),
                size: 44
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.appSans(AppTheme.Typography.fontBody, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                PlanBadge(text: rule.frequency.capitalized)
            }
            Spacer()
            Text("\(isIncome ? "+" : "-")\(store.formatAmount(rule.amount))")
                .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                .foregroundStyle(isIncome ? AppTheme.Colors.income : AppTheme.Colors.expense)
        }
        .planRow()
    }

    private func delete(_ rule: RecurringRule) {
        modelContext.delete(rule)
        try? modelContext.save()
    }
}

// MARK: - Section 2: Trips

private struct TripsSection: View {
    @Environment(DataStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Trip.name) private var trips: [Trip]
    @Query private var transactions: [Transaction]

    @State private var showingForm = false
    @State private var tripToDelete: Trip?

    var body: some View {
        PlanSectionCard(title: "Trips", systemImage: "airplane", pastel: .sky) {
            showingForm = true
        } content: {
            if trips.isEmpty {
                PlanEmptyRow(text: "No trips yet")
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(trips) { trip in
                        tripCard(trip)
                    }
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            TripFormView()
        }
        .confirmationDialog(
            "Delete this trip?",
            isPresented: Binding(get: { tripToDelete != nil }, set: { if !$0 { tripToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let trip = tripToDelete { delete(trip) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func spent(on trip: Trip) -> Double {
        transactions
            .filter { $0.tripId == trip.id && $0.type == "expense" }
            .reduce(0) { $0 + $1.amount }
    }

    private func tripCard(_ trip: Trip) -> some View {
        let total = spent(on: trip)
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Text(trip.name)
                    .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                if trip.isActive {
                    PlanBadge(text: "Active")
                }
                Spacer()
                Button { toggleActive(trip) } label: {
                    Text(trip.isActive ? "Stop" : "Start")
                        .font(.appSans(AppTheme.Typography.fontLabel, weight: .semibold))
                        .foregroundStyle(trip.isActive ? .white : AppTheme.Colors.accent)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, 6)
                        .background(trip.isActive ? AppTheme.Colors.accent : AppTheme.Colors.accent.opacity(0.15))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                Button { tripToDelete = trip } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.expense)
                }
                .buttonStyle(.plain)
            }

            if trip.budget > 0 {
                PlanProgressBar(ratio: total / trip.budget, color: AppTheme.Colors.accent)
                Text("\(store.formatAmount(total)) / \(store.formatAmount(trip.budget))")
                    .font(.appSans(AppTheme.Typography.fontLabel, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            } else {
                Text("Spent \(store.formatAmount(total))")
                    .font(.appSans(AppTheme.Typography.fontLabel, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
        }
        .planRow()
    }

    /// Activates a trip (clearing any other active trip) or stops it.
    private func toggleActive(_ trip: Trip) {
        let activating = !trip.isActive
        for other in trips where other.id != trip.id {
            other.isActive = false
        }
        trip.isActive = activating
        store.activeTripId = activating ? trip.id : nil
        try? modelContext.save()
    }

    private func delete(_ trip: Trip) {
        if store.activeTripId == trip.id { store.activeTripId = nil }
        modelContext.delete(trip)
        try? modelContext.save()
    }
}

// MARK: - Section 3: Savings Goals

private struct SavingsGoalsSection: View {
    @Environment(DataStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \SavingsGoal.name) private var goals: [SavingsGoal]

    @State private var showingForm = false
    @State private var goalForDeposit: SavingsGoal?
    @State private var depositText = ""

    var body: some View {
        PlanSectionCard(title: "Savings Goals", systemImage: "target", pastel: .mint) {
            showingForm = true
        } content: {
            if goals.isEmpty {
                PlanEmptyRow(text: "No savings goals yet")
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(goals) { goal in
                        SwipeToDeleteContainer(confirmTitle: "Delete this goal?") {
                            delete(goal)
                        } content: {
                            goalCard(goal)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            SavingsGoalFormView()
        }
        .alert(
            "Add Savings",
            isPresented: Binding(get: { goalForDeposit != nil }, set: { if !$0 { goalForDeposit = nil } })
        ) {
            TextField("Amount", text: $depositText)
                .keyboardType(.decimalPad)
            Button("Add") { commitDeposit() }
            Button("Cancel", role: .cancel) { depositText = "" }
        } message: {
            Text("Add an amount toward \(goalForDeposit?.name ?? "this goal").")
        }
    }

    private func goalCard(_ goal: SavingsGoal) -> some View {
        let complete = goal.saved >= goal.target && goal.target > 0
        let ratio = goal.target > 0 ? goal.saved / goal.target : 0
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                IconBadge(
                    symbol: planSymbol(goal.emoji, fallback: "target"),
                    style: .mint,
                    size: 40
                )
                Text(goal.name)
                    .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                if complete {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.Colors.income)
                }
                Spacer()
                Button {
                    depositText = ""
                    goalForDeposit = goal
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.Colors.accent)
                }
                .buttonStyle(.plain)
            }

            PlanProgressBar(ratio: ratio, color: complete ? AppTheme.Colors.income : AppTheme.Colors.accent)

            Text("\(store.formatAmount(goal.saved)) / \(store.formatAmount(goal.target))")
                .font(.appSans(AppTheme.Typography.fontLabel, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textMuted)
        }
        .planRow()
    }

    private func commitDeposit() {
        defer { depositText = ""; goalForDeposit = nil }
        guard let goal = goalForDeposit,
              let amount = Double(depositText.replacingOccurrences(of: ",", with: ".")),
              amount > 0 else { return }
        let wasComplete = goal.target > 0 && goal.saved >= goal.target
        goal.saved = min(goal.target, goal.saved + amount)
        try? modelContext.save()
        // Celebrate the moment the goal crosses 100% (but not on further deposits
        // to an already-complete goal).
        if !wasComplete && goal.target > 0 && goal.saved >= goal.target {
            HapticManager.success()
        }
    }

    private func delete(_ goal: SavingsGoal) {
        modelContext.delete(goal)
        try? modelContext.save()
    }
}

// MARK: - Section 4: Subscriptions

private struct SubscriptionsSection: View {
    @Environment(DataStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]

    @State private var showingForm = false

    /// Monthly cost: monthly amounts as-is, yearly amounts divided by 12.
    private var monthlyTotal: Double {
        subscriptions.reduce(0) { sum, sub in
            sum + (sub.period == "yearly" ? sub.amount / 12 : sub.amount)
        }
    }

    var body: some View {
        PlanSectionCard(title: "Subscriptions", systemImage: "creditcard.fill", pastel: .lavender) {
            showingForm = true
        } content: {
            if subscriptions.isEmpty {
                PlanEmptyRow(text: "No subscriptions yet")
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(subscriptions) { sub in
                        SwipeToDeleteContainer(confirmTitle: "Delete this subscription?") {
                            delete(sub)
                        } content: {
                            subscriptionRow(sub)
                        }
                    }
                    totalFooter
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            SubscriptionFormView()
        }
    }

    private func subscriptionRow(_ sub: Subscription) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            IconBadge(
                symbol: planSymbol(sub.emoji, fallback: "creditcard.fill"),
                style: .lavender,
                size: 44
            )
            Text(sub.name)
                .font(.appSans(AppTheme.Typography.fontBody, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            PlanBadge(text: sub.period.capitalized)
            Spacer()
            Text(store.formatAmount(sub.amount))
                .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .planRow()
    }

    private var totalFooter: some View {
        HStack {
            Text("Monthly total")
                .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Spacer()
            Text(store.formatAmount(monthlyTotal))
                .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .padding(.top, AppTheme.Spacing.xs)
    }

    private func delete(_ sub: Subscription) {
        modelContext.delete(sub)
        try? modelContext.save()
    }
}

// MARK: - Form: Recurring

private struct RecurringFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(DataStore.self) private var store

    @Query(sort: \Wallet.name) private var wallets: [Wallet]
    @Query(sort: \AppCategory.label) private var categories: [AppCategory]

    @State private var type = "expense"
    @State private var amountText = ""
    @State private var frequency = "monthly"
    @State private var walletId = ""
    @State private var categoryId = ""
    @State private var note = ""

    private let frequencies = ["weekly", "monthly", "yearly"]

    private var amountValue: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    private var canSave: Bool { amountValue > 0 && !walletId.isEmpty && !categoryId.isEmpty }
    private var accent: Color { type == "income" ? AppTheme.Colors.income : AppTheme.Colors.expense }
    private var visibleCategories: [AppCategory] { categories.filter { $0.type == type } }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        typeToggle
                        amountField
                        frequencyPicker
                        walletSection
                        categorySection
                        noteSection
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationTitle("New Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? accent : AppTheme.Colors.textMuted)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadInitialState)
            .onChange(of: type) { _, _ in ensureCategoryMatchesType() }
        }
    }

    private var typeToggle: some View {
        HStack(spacing: 0) {
            typeSegment("Expense", "expense", AppTheme.Colors.expense)
            typeSegment("Income", "income", AppTheme.Colors.income)
        }
        .padding(4)
        .background(AppTheme.Colors.surface)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.Colors.border, lineWidth: 1))
    }

    private func typeSegment(_ title: String, _ value: String, _ color: Color) -> some View {
        let isSelected = type == value
        return Button {
            withAnimation(.easeOut(duration: 0.2)) { type = value }
        } label: {
            Text(title)
                .font(.appSans(15, weight: .semibold))
                .foregroundStyle(isSelected ? .white : AppTheme.Colors.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? color : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var amountField: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            sectionLabel("Amount").frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(DataStore.currencyInfo(for: store.currencyCode).symbol)
                    .font(.appSans(30, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textMuted)
                TextField("0", text: $amountText)
                    .font(.appSans(44, weight: .semibold))
                    .foregroundStyle(accent)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .cardStyle()
    }

    private var frequencyPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionLabel("Frequency")
            Picker("Frequency", selection: $frequency) {
                ForEach(frequencies, id: \.self) { freq in
                    Text(freq.capitalized).tag(freq)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var walletSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionLabel("Wallet")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(Array(wallets.enumerated()), id: \.element.id) { index, wallet in
                        walletChip(wallet, index: index)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private func walletChip(_ wallet: Wallet, index: Int) -> some View {
        let isSelected = wallet.id == walletId
        return Button { walletId = wallet.id } label: {
            HStack(spacing: 8) {
                IconBadge(
                    symbol: IconMap.symbol(forWallet: wallet.id),
                    style: IconMap.pastel(forIndex: index),
                    size: 24
                )
                Text(wallet.name).font(.appSans(14, weight: .medium))
            }
            .padding(.leading, 6)
            .padding(.trailing, AppTheme.Spacing.md)
            .padding(.vertical, 6)
            .background(isSelected ? accent : AppTheme.Colors.surface)
            .foregroundStyle(isSelected ? .white : AppTheme.Colors.textPrimary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? accent : AppTheme.Colors.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionLabel("Category")
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.sm), count: 4),
                spacing: AppTheme.Spacing.sm
            ) {
                ForEach(visibleCategories) { category in
                    categoryCell(category)
                }
            }
        }
    }

    private func categoryCell(_ category: AppCategory) -> some View {
        let isSelected = category.id == categoryId
        return Button { categoryId = category.id } label: {
            VStack(spacing: 6) {
                IconBadge(
                    symbol: IconMap.symbol(forCategory: category.id),
                    style: IconMap.pastel(forCategory: category.id),
                    size: 40
                )
                Text(category.label)
                    .font(.appSans(11))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(isSelected ? AppTheme.Colors.accent.opacity(0.12) : AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                    .stroke(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var noteSection: some View {
        HStack {
            Text("Note")
                .font(.appSans(15))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Spacer()
            TextField("Optional", text: $note)
                .multilineTextAlignment(.trailing)
                .font(.appSans(15))
        }
        .cardStyle()
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.appSans(AppTheme.Typography.fontLabel, weight: .semibold))
            .foregroundStyle(AppTheme.Colors.textMuted)
    }

    private func loadInitialState() {
        walletId = wallets.first(where: { $0.isDefault })?.id ?? wallets.first?.id ?? ""
        ensureCategoryMatchesType()
    }

    private func ensureCategoryMatchesType() {
        if !visibleCategories.contains(where: { $0.id == categoryId }) {
            categoryId = visibleCategories.first?.id ?? ""
        }
    }

    private func save() {
        guard canSave else { return }
        let rule = RecurringRule(
            type: type,
            amount: amountValue,
            categoryId: categoryId,
            walletId: walletId,
            note: note,
            frequency: frequency,
            startDate: .now,
            lastRun: .now
        )
        modelContext.insert(rule)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Form: Trip

private struct TripFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(DataStore.self) private var store

    @State private var name = ""
    @State private var budgetText = ""

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.md) {
                        HStack {
                            Text("Name")
                                .font(.appSans(15))
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Spacer()
                            TextField("Trip name", text: $name)
                                .multilineTextAlignment(.trailing)
                                .font(.appSans(15))
                        }
                        Divider()
                        HStack {
                            Text("Budget")
                                .font(.appSans(15))
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Spacer()
                            TextField("Optional", text: $budgetText)
                                .multilineTextAlignment(.trailing)
                                .font(.appSans(15))
                                .keyboardType(.decimalPad)
                        }
                    }
                    .cardStyle()
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? AppTheme.Colors.accent : AppTheme.Colors.textMuted)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard canSave else { return }
        let budget = Double(budgetText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let trip = Trip(name: name.trimmingCharacters(in: .whitespaces), budget: budget, isActive: false)
        modelContext.insert(trip)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Form: Savings Goal

private struct SavingsGoalFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var targetText = ""
    // The model's `emoji` field now stores an SF Symbol name (see planSymbol).
    @State private var emoji = "target"

    private let symbolChoices = [
        "target", "house.fill", "airplane", "car.fill", "laptopcomputer",
        "gift.fill", "heart.fill", "graduationcap.fill", "figure.run", "leaf.fill",
    ]

    private var targetValue: Double {
        Double(targetText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && targetValue > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        VStack(spacing: AppTheme.Spacing.md) {
                            HStack {
                                Text("Name")
                                    .font(.appSans(15))
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                Spacer()
                                TextField("Goal name", text: $name)
                                    .multilineTextAlignment(.trailing)
                                    .font(.appSans(15))
                            }
                            Divider()
                            HStack {
                                Text("Target")
                                    .font(.appSans(15))
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                Spacer()
                                TextField("0", text: $targetText)
                                    .multilineTextAlignment(.trailing)
                                    .font(.appSans(15))
                                    .keyboardType(.decimalPad)
                            }
                        }
                        .cardStyle()

                        iconPicker
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? AppTheme.Colors.accent : AppTheme.Colors.textMuted)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Icon")
                .font(.appSans(AppTheme.Typography.fontLabel, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textMuted)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.sm), count: 5),
                spacing: AppTheme.Spacing.sm
            ) {
                ForEach(symbolChoices, id: \.self) { choice in
                    let isSelected = choice == emoji
                    Button { emoji = choice } label: {
                        IconBadge(symbol: choice, style: .mint, size: 36)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(isSelected ? AppTheme.Colors.accent.opacity(0.12) : AppTheme.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                                    .stroke(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.border, lineWidth: isSelected ? 2 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func save() {
        guard canSave else { return }
        let goal = SavingsGoal(
            name: name.trimmingCharacters(in: .whitespaces),
            target: targetValue,
            saved: 0,
            emoji: emoji
        )
        modelContext.insert(goal)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Form: Subscription

private struct SubscriptionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    // The model's `emoji` field now stores an SF Symbol name (see planSymbol).
    @State private var emoji = "creditcard.fill"
    @State private var amountText = ""
    @State private var period = "monthly"

    private struct Preset: Identifiable {
        let name: String
        let symbol: String
        var id: String { name }
    }
    private let presets: [Preset] = [
        .init(name: "Netflix", symbol: "film.fill"),
        .init(name: "Spotify", symbol: "music.note"),
        .init(name: "YouTube", symbol: "play.rectangle.fill"),
        .init(name: "iCloud", symbol: "cloud.fill"),
        .init(name: "Apple Music", symbol: "music.note.list"),
        .init(name: "Gym", symbol: "figure.run"),
    ]

    private var amountValue: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && amountValue > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        presetSection
                        detailsSection
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationTitle("New Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? AppTheme.Colors.accent : AppTheme.Colors.textMuted)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Presets")
                .font(.appSans(AppTheme.Typography.fontLabel, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textMuted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(Array(presets.enumerated()), id: \.element.id) { index, preset in
                        Button {
                            name = preset.name
                            emoji = preset.symbol
                        } label: {
                            HStack(spacing: 8) {
                                IconBadge(symbol: preset.symbol, style: IconMap.pastel(forIndex: index), size: 24)
                                Text(preset.name).font(.appSans(14, weight: .medium))
                            }
                            .padding(.leading, 6)
                            .padding(.trailing, AppTheme.Spacing.md)
                            .padding(.vertical, 6)
                            .background(name == preset.name ? AppTheme.Colors.accent : AppTheme.Colors.surface)
                            .foregroundStyle(name == preset.name ? .white : AppTheme.Colors.textPrimary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(name == preset.name ? AppTheme.Colors.accent : AppTheme.Colors.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private var detailsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                IconBadge(symbol: planSymbol(emoji, fallback: "creditcard.fill"), style: .lavender, size: 32)
                TextField("Name", text: $name)
                    .font(.appSans(15))
            }
            Divider()
            HStack {
                Text("Amount")
                    .font(.appSans(15))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
                TextField("0", text: $amountText)
                    .multilineTextAlignment(.trailing)
                    .font(.appSans(15))
                    .keyboardType(.decimalPad)
            }
            Divider()
            Picker("Period", selection: $period) {
                Text("Monthly").tag("monthly")
                Text("Yearly").tag("yearly")
            }
            .pickerStyle(.segmented)
        }
        .cardStyle()
    }

    private func save() {
        guard canSave else { return }
        let sub = Subscription(
            name: name.trimmingCharacters(in: .whitespaces),
            amount: amountValue,
            period: period,
            emoji: emoji
        )
        modelContext.insert(sub)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    PlansView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
