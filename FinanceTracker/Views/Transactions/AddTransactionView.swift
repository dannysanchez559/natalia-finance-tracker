//
//  AddTransactionView.swift
//  Finna
//
//  Add / Edit transaction sheet. Type toggle, amount, wallet chips,
//  category grid, date, and an optional note. Writes to SwiftData.
//  If a trip is active and the type is Expense, the new transaction is
//  auto-tagged with that trip id.
//

import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(DataStore.self) private var store

    /// Pass an existing transaction to edit it; nil creates a new one.
    var editing: Transaction?

    @Query(sort: \Wallet.name) private var wallets: [Wallet]
    @Query(sort: \AppCategory.label) private var categories: [AppCategory]

    @State private var type: String = "expense"
    @State private var amountText: String = ""
    @State private var walletId: String = ""
    @State private var categoryId: String = ""
    @State private var date: Date = .now
    @State private var note: String = ""

    private var amountValue: Double { Double(amountText) ?? 0 }
    private var canSave: Bool { amountValue > 0 && !walletId.isEmpty && !categoryId.isEmpty }
    private var isEditing: Bool { editing != nil }

    private var visibleCategories: [AppCategory] {
        categories.filter { $0.type == type }
    }

    private var accent: Color {
        type == "income" ? AppTheme.Colors.income : AppTheme.Colors.expense
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        typePicker
                        amountField
                        walletSection
                        categorySection
                        detailsSection
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationTitle(isEditing ? "Edit Transaction" : "New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadInitialState)
            .onChange(of: type) { _, _ in ensureCategoryMatchesType() }
        }
    }

    // MARK: - Sections

    private var typePicker: some View {
        Picker("Type", selection: $type) {
            Text("Expense").tag("expense")
            Text("Income").tag("income")
        }
        .pickerStyle(.segmented)
    }

    private var amountField: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("Amount")
                .font(.appSans(12, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Text(DataStore.currencyInfo(for: store.currencyCode).symbol)
                    .font(.appSerif(34, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textMuted)
                TextField("0", text: $amountText)
                    .font(.appSerif(40, weight: .semibold))
                    .foregroundStyle(accent)
                    .keyboardType(.decimalPad)
            }
        }
        .cardStyle()
    }

    private var walletSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionLabel("Wallet")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(wallets) { wallet in
                        chip(
                            emoji: wallet.emoji,
                            label: wallet.name,
                            isSelected: wallet.id == walletId
                        ) { walletId = wallet.id }
                    }
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionLabel("Category")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.sm), count: 4),
                      spacing: AppTheme.Spacing.sm) {
                ForEach(visibleCategories) { category in
                    categoryCell(category)
                }
            }
        }
    }

    private var detailsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .font(.appSans(15))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Divider()

            HStack {
                Text("Note")
                    .font(.appSans(15))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
                TextField("Optional", text: $note)
                    .multilineTextAlignment(.trailing)
                    .font(.appSans(15))
            }
        }
        .cardStyle()
    }

    // MARK: - Building Blocks

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.appSans(12, weight: .semibold))
            .foregroundStyle(AppTheme.Colors.textMuted)
    }

    private func chip(emoji: String, label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji)
                Text(label)
                    .font(.appSans(14, weight: .medium))
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(isSelected ? AppTheme.Colors.accent.opacity(0.18) : AppTheme.Colors.surface)
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.border, lineWidth: 1)
            )
        }
    }

    private func categoryCell(_ category: AppCategory) -> some View {
        let isSelected = category.id == categoryId
        return Button { categoryId = category.id } label: {
            VStack(spacing: 4) {
                Text(category.emoji)
                    .font(.system(size: 24))
                Text(category.label)
                    .font(.appSans(11))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(isSelected ? Color(hex: category.colorHex).opacity(0.18) : AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                    .stroke(isSelected ? Color(hex: category.colorHex) : AppTheme.Colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - State

    private func loadInitialState() {
        if let tx = editing {
            type = tx.type
            amountText = tx.amount == 0 ? "" : String(format: "%g", tx.amount)
            walletId = tx.walletId
            categoryId = tx.categoryId
            date = tx.date
            note = tx.note
        } else {
            // Default to the Cash wallet (or the first available).
            walletId = wallets.first(where: { $0.id == "wallet-cash" })?.id
                ?? wallets.first?.id ?? ""
            ensureCategoryMatchesType()
        }
    }

    /// Keeps the selected category valid for the current type.
    private func ensureCategoryMatchesType() {
        if !visibleCategories.contains(where: { $0.id == categoryId }) {
            categoryId = visibleCategories.first?.id ?? ""
        }
    }

    private func save() {
        guard canSave else { return }

        // Auto-tag to the active trip for expenses only.
        let tripId = (type == "expense") ? store.activeTripId : nil

        if let tx = editing {
            tx.type = type
            tx.amount = amountValue
            tx.walletId = walletId
            tx.categoryId = categoryId
            tx.date = date
            tx.note = note
            tx.currencyCode = store.currencyCode
            tx.tripId = tripId
        } else {
            let tx = Transaction(
                type: type,
                amount: amountValue,
                currencyCode: store.currencyCode,
                categoryId: categoryId,
                walletId: walletId,
                note: note,
                tripId: tripId,
                date: date
            )
            modelContext.insert(tx)
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddTransactionView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
