//
//  AddTransactionView.swift
//  Finna
//
//  Add / Edit transaction sheet — the most-used flow in the app.
//  Type toggle (color-themed), large serif amount field, wallet chip row,
//  4-column category grid, date picker, optional note and tags.
//  Writes to SwiftData. If a trip is active and the type is Expense, the
//  transaction is auto-tagged with that trip id.
//
//  Receives an optional `editing` Transaction: nil creates a new record,
//  non-nil edits the existing one in place.
//

import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(DataStore.self) private var store

    /// Pass an existing transaction to edit it; nil creates a new one.
    var editing: Transaction?

    init(editing: Transaction? = nil) {
        self.editing = editing
    }

    @Query(sort: \Wallet.name) private var wallets: [Wallet]
    @Query(sort: \AppCategory.label) private var categories: [AppCategory]

    @State private var type: String = "expense"
    @State private var amountText: String = ""
    @State private var walletId: String = ""
    @State private var categoryId: String = ""
    @State private var date: Date = .now
    @State private var note: String = ""
    @State private var tagsText: String = ""

    private var amountValue: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    private var canSave: Bool { amountValue > 0 && !walletId.isEmpty && !categoryId.isEmpty }
    private var isEditing: Bool { editing != nil }

    private var visibleCategories: [AppCategory] {
        categories.filter { $0.type == type }
    }

    /// Active accent shifts with the selected transaction type.
    private var accent: Color {
        type == "income" ? AppTheme.Colors.income : AppTheme.Colors.expense
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        typeToggle
                        amountField
                        walletSection
                        categorySection
                        detailsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, AppTheme.Spacing.md)
                }
            }
            .navigationTitle(isEditing ? "Edit Transaction" : "New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save Changes" : "Save", action: save)
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? accent : AppTheme.Colors.textMuted)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadInitialState)
            .onChange(of: type) { _, _ in ensureCategoryMatchesType() }
        }
    }

    // MARK: - Type Toggle

    private var typeToggle: some View {
        HStack(spacing: 0) {
            typeSegment(title: "Expense", value: "expense", color: AppTheme.Colors.expense)
            typeSegment(title: "Income", value: "income", color: AppTheme.Colors.income)
        }
        .padding(4)
        .background(AppTheme.Colors.surface)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.Colors.border, lineWidth: 1))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: type)
    }

    private func typeSegment(title: String, value: String, color: Color) -> some View {
        let isSelected = type == value
        return Button {
            type = value
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

    // MARK: - Amount

    private var amountField: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            sectionLabel("Amount")
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(DataStore.currencyInfo(for: store.currencyCode).symbol)
                    .font(.appSerif(30, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textMuted)
                TextField("0", text: $amountText)
                    .font(.appSerif(44, weight: .semibold))
                    .foregroundStyle(accent)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .cardStyle()
    }

    // MARK: - Wallet

    private var walletSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            sectionLabel("Wallet")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(Array(wallets.enumerated()), id: \.element.id) { index, wallet in
                        walletChip(wallet, index: index)
                    }
                }
                .padding(.horizontal, 1) // keeps stroke from clipping
            }
        }
    }

    private func walletChip(_ wallet: Wallet, index: Int) -> some View {
        let isSelected = wallet.id == walletId
        return Button {
            walletId = wallet.id
        } label: {
            HStack(spacing: 8) {
                IconBadge(
                    symbol: IconMap.symbol(forWallet: wallet.id),
                    style: IconMap.pastel(forIndex: index),
                    size: 24
                )
                Text(wallet.name)
                    .font(.appSans(14, weight: .medium))
            }
            .padding(.leading, 6)
            .padding(.trailing, AppTheme.Spacing.md)
            .padding(.vertical, 6)
            .background(isSelected ? accent : AppTheme.Colors.surface)
            .foregroundStyle(isSelected ? .white : AppTheme.Colors.textPrimary)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? accent : AppTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category

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
                newCategoryCell
            }
        }
    }

    private func categoryCell(_ category: AppCategory) -> some View {
        let isSelected = category.id == categoryId
        return Button {
            categoryId = category.id
        } label: {
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

    /// "+ New" stub — Add Category sheet is wired in a later Phase 4 screen.
    private var newCategoryCell: some View {
        Button {
            // TODO: Phase 4 — present Add Category sheet.
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textMuted)
                Text("New")
                    .font(.appSans(11))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(AppTheme.Colors.border)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Details (date, note, tags)

    private var detailsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .font(.appSans(15))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .tint(accent)

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

            Divider()

            HStack {
                Text("Tags")
                    .font(.appSans(15))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
                TextField("comma, separated", text: $tagsText)
                    .multilineTextAlignment(.trailing)
                    .font(.appSans(15))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
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

    // MARK: - State

    private func loadInitialState() {
        if let tx = editing {
            type = tx.type
            amountText = tx.amount == 0 ? "" : String(format: "%g", tx.amount)
            walletId = tx.walletId
            categoryId = tx.categoryId
            date = tx.date
            note = tx.note
            tagsText = tx.tags.joined(separator: ", ")
        } else {
            // Default to the user's default wallet (or the first available).
            walletId = wallets.first(where: { $0.isDefault })?.id
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

    private func parsedTags() -> [String] {
        tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
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
            tx.tags = parsedTags()
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
                tags: parsedTags(),
                tripId: tripId,
                date: date
            )
            modelContext.insert(tx)
        }

        try? modelContext.save()
        HapticManager.impact()
        dismiss()
    }
}

#Preview {
    AddTransactionView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
