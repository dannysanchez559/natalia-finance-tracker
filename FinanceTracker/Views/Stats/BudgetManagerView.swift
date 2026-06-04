//
//  BudgetManagerView.swift
//  Finna
//
//  Sheet for setting per-category monthly spending limits. Lists every expense
//  category with a numeric field pre-filled from the existing limits in
//  UserDefaults ([String: Double] keyed by categoryId). All edits are written
//  back on dismiss; a per-row clear button removes that category's limit.
//

import SwiftUI
import SwiftData

struct BudgetManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var store

    @Query private var categories: [AppCategory]

    // Editable text mirror of the limits, keyed by categoryId. Empty/zero
    // entries are dropped when written back on dismiss.
    @State private var limitText: [String: String] = [:]

    private var expenseCategories: [AppCategory] {
        categories.filter { $0.type == "expense" }.sorted { $0.label < $1.label }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(expenseCategories) { category in
                        budgetRow(category)
                    }
                } footer: {
                    Text("Set a monthly spending limit per category. Leave blank for no limit.")
                        .font(.appSans(AppTheme.Typography.fontLabel))
                        .foregroundStyle(AppTheme.Colors.textMuted)
                }
                .listRowBackground(AppTheme.Colors.surface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.background)
            .navigationTitle("Budgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { saveAndDismiss() }
                        .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                        .tint(AppTheme.Colors.accent)
                }
            }
            .onAppear(perform: loadLimits)
        }
    }

    // MARK: - Row

    private func budgetRow(_ category: AppCategory) -> some View {
        let binding = Binding(
            get: { limitText[category.id] ?? "" },
            set: { limitText[category.id] = $0 }
        )
        let hasValue = !(limitText[category.id] ?? "").isEmpty

        return HStack(spacing: AppTheme.Spacing.sm) {
            Text(category.emoji)
                .font(.system(size: 18))
            Text(category.label)
                .font(.appSans(AppTheme.Typography.fontBody, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            TextField("0", text: binding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.appSans(AppTheme.Typography.fontCardNumber, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .frame(maxWidth: 100)

            Button {
                limitText[category.id] = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.Colors.textMuted.opacity(hasValue ? 0.6 : 0.2))
            }
            .buttonStyle(.plain)
            .disabled(!hasValue)
        }
    }

    // MARK: - Actions

    private func loadLimits() {
        limitText = store.budgetLimits.mapValues { value in
            // Drop a trailing ".0" so whole numbers show cleanly.
            value == value.rounded() ? String(Int(value)) : String(value)
        }
    }

    private func saveAndDismiss() {
        var limits: [String: Double] = [:]
        for (categoryId, text) in limitText {
            let cleaned = text.trimmingCharacters(in: .whitespaces)
            if let value = Double(cleaned), value > 0 {
                limits[categoryId] = value
            }
        }
        store.budgetLimits = limits
        dismiss()
    }
}

#Preview {
    BudgetManagerView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
