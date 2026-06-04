//
//  CurrencyPickerView.swift
//  Finna
//
//  Sheet for choosing the global display currency. Selecting a row
//  updates DataStore.currencyCode (persisted to UserDefaults) and dismisses.
//

import SwiftUI

struct CurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var store

    /// Full currency names keyed by code. Symbols come from `DataStore.currencies`.
    private static let names: [String: String] = [
        "USD": "US Dollar",
        "EUR": "Euro",
        "GBP": "British Pound",
        "AED": "UAE Dirham",
        "RUB": "Russian Ruble",
        "JPY": "Japanese Yen",
        "CNY": "Chinese Yuan",
        "KZT": "Kazakhstani Tenge",
        "TRY": "Turkish Lira",
        "INR": "Indian Rupee",
        "CHF": "Swiss Franc",
        "CAD": "Canadian Dollar",
        "AUD": "Australian Dollar",
        "THB": "Thai Baht",
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(DataStore.currencies, id: \.code) { currency in
                    Button {
                        select(currency.code)
                    } label: {
                        row(for: currency)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.background)
            .navigationTitle("Display Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                }
            }
        }
    }

    private func row(for currency: DataStore.CurrencyInfo) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text(currency.symbol)
                .font(.appSans(AppTheme.Typography.fontCardNumber, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accent)
                .frame(width: 44, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(currency.code)
                    .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(Self.names[currency.code] ?? currency.code)
                    .font(.appSans(AppTheme.Typography.fontLabel))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }

            Spacer()

            if currency.code == store.currencyCode {
                Image(systemName: "checkmark")
                    .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
            }
        }
    }

    private func select(_ code: String) {
        store.currencyCode = code
        dismiss()
    }
}

#Preview {
    CurrencyPickerView()
        .environment(DataStore())
}
