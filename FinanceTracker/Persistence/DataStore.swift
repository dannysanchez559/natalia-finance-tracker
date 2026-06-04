//
//  DataStore.swift
//  Finna
//
//  Owns the SwiftData container, lightweight UserDefaults settings,
//  first-launch seeding, recurring-rule processing, and amount formatting.
//

import Foundation
import SwiftData
import SwiftUI

/// A saved one-tap shortcut. Tapping it creates a transaction with today's
/// date and these fields. Persisted (max 6) to UserDefaults as JSON.
struct QuickAction: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var type: String
    var amount: Double
    var categoryId: String
    var walletId: String
    var note: String
}

@Observable
final class DataStore {

    // MARK: - Shared Model Container

    static let modelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Wallet.self,
            AppCategory.self,
            Trip.self,
            SavingsGoal.self,
            Subscription.self,
            RecurringRule.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    // MARK: - UserDefaults-backed Settings

    private enum Keys {
        static let currencyCode = "currencyCode"
        static let isDarkMode = "isDarkMode"
        static let hasOnboarded = "hasOnboarded"
        static let activeTripId = "activeTripId"
        static let budgetLimits = "budgetLimits"
        static let quickActions = "quickActions"
        static let recurringProcessorV1 = "recurringProcessorV1"
    }

    var currencyCode: String {
        get { UserDefaults.standard.string(forKey: Keys.currencyCode) ?? "USD" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.currencyCode) }
    }

    // Stored (not computed) so @Observable tracks it and the toggle updates the
    // UI live. Seeded once from UserDefaults; didSet writes changes back.
    var isDarkMode: Bool = UserDefaults.standard.bool(forKey: Keys.isDarkMode) {
        didSet { UserDefaults.standard.set(isDarkMode, forKey: Keys.isDarkMode) }
    }

    var hasOnboarded: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasOnboarded) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasOnboarded) }
    }

    var activeTripId: String? {
        get { UserDefaults.standard.string(forKey: Keys.activeTripId) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.activeTripId) }
    }

    /// Per-category monthly budget limits, keyed by `categoryId`. Set in Stats.
    var budgetLimits: [String: Double] {
        get { UserDefaults.standard.dictionary(forKey: Keys.budgetLimits) as? [String: Double] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: Keys.budgetLimits) }
    }

    /// Saved quick-add shortcuts (max 6). Stored as JSON.
    var quickActions: [QuickAction] {
        get {
            guard let data = UserDefaults.standard.data(forKey: Keys.quickActions),
                  let decoded = try? JSONDecoder().decode([QuickAction].self, from: data)
            else { return [] }
            return decoded
        }
        set {
            let capped = Array(newValue.prefix(6))
            if let data = try? JSONEncoder().encode(capped) {
                UserDefaults.standard.set(data, forKey: Keys.quickActions)
            }
        }
    }

    // MARK: - Currency Catalog

    /// 14 supported display currencies. `symbolBeforeAmount` controls placement.
    struct CurrencyInfo {
        let code: String
        let symbol: String
        let symbolBeforeAmount: Bool
    }

    static let currencies: [CurrencyInfo] = [
        .init(code: "USD", symbol: "$",   symbolBeforeAmount: true),
        .init(code: "EUR", symbol: "€",   symbolBeforeAmount: true),
        .init(code: "GBP", symbol: "£",   symbolBeforeAmount: true),
        .init(code: "AED", symbol: "AED", symbolBeforeAmount: false),
        .init(code: "RUB", symbol: "₽",   symbolBeforeAmount: false),
        .init(code: "JPY", symbol: "¥",   symbolBeforeAmount: true),
        .init(code: "CNY", symbol: "¥",   symbolBeforeAmount: true),
        .init(code: "KZT", symbol: "₸",   symbolBeforeAmount: false),
        .init(code: "TRY", symbol: "₺",   symbolBeforeAmount: true),
        .init(code: "INR", symbol: "₹",   symbolBeforeAmount: true),
        .init(code: "CHF", symbol: "CHF", symbolBeforeAmount: false),
        .init(code: "CAD", symbol: "C$",  symbolBeforeAmount: true),
        .init(code: "AUD", symbol: "A$",  symbolBeforeAmount: true),
        .init(code: "THB", symbol: "฿",   symbolBeforeAmount: true),
    ]

    static func currencyInfo(for code: String) -> CurrencyInfo {
        currencies.first { $0.code == code } ?? currencies[0]
    }

    // MARK: - Seeding

    /// Inserts default wallets and categories on first launch (when the store is empty).
    func seedIfNeeded(context: ModelContext) {
        let existing = try? context.fetch(FetchDescriptor<Wallet>())
        guard (existing?.isEmpty ?? true) else { return }

        // Default wallets
        let wallets: [Wallet] = [
            Wallet(id: "wallet-cash",    name: "Cash",    emoji: "💵", colorHex: "#7AC9A6", isDefault: true),
            Wallet(id: "wallet-card",    name: "Card",    emoji: "💳", colorHex: "#7A9CC6", isDefault: true),
            Wallet(id: "wallet-savings", name: "Savings", emoji: "🐷", colorHex: "#D4A574", isDefault: true),
        ]

        // Default expense categories
        let expenseCategories: [AppCategory] = [
            AppCategory(id: "cat-food",     label: "Food",     emoji: "🍕", colorHex: "#E07060", type: "expense", isDefault: true),
            AppCategory(id: "cat-transport", label: "Transport", emoji: "🚌", colorHex: "#7A9CC6", type: "expense", isDefault: true),
            AppCategory(id: "cat-home",     label: "Home",     emoji: "🏠", colorHex: "#A67AC9", type: "expense", isDefault: true),
            AppCategory(id: "cat-fun",      label: "Fun",      emoji: "🎬", colorHex: "#C97AAF", type: "expense", isDefault: true),
            AppCategory(id: "cat-health",   label: "Health",   emoji: "💊", colorHex: "#7AC9A6", type: "expense", isDefault: true),
            AppCategory(id: "cat-shopping", label: "Shopping", emoji: "🛍️", colorHex: "#D4A574", type: "expense", isDefault: true),
            AppCategory(id: "cat-travel",   label: "Travel",   emoji: "✈️", colorHex: "#6AB4D4", type: "expense", isDefault: true),
            AppCategory(id: "cat-other-exp", label: "Other",   emoji: "📌", colorHex: "#8A7A66", type: "expense", isDefault: true),
        ]

        // Default income categories
        let incomeCategories: [AppCategory] = [
            AppCategory(id: "cat-salary",     label: "Salary",     emoji: "💼", colorHex: "#7A9C7A", type: "income", isDefault: true),
            AppCategory(id: "cat-freelance",  label: "Freelance",  emoji: "💻", colorHex: "#9AC97A", type: "income", isDefault: true),
            AppCategory(id: "cat-gift",       label: "Gift",       emoji: "🎁", colorHex: "#C9B87A", type: "income", isDefault: true),
            AppCategory(id: "cat-investment", label: "Investment", emoji: "📈", colorHex: "#7AC9B8", type: "income", isDefault: true),
            AppCategory(id: "cat-other-inc",  label: "Other",      emoji: "✨", colorHex: "#B8A87A", type: "income", isDefault: true),
        ]

        wallets.forEach { context.insert($0) }
        expenseCategories.forEach { context.insert($0) }
        incomeCategories.forEach { context.insert($0) }

        try? context.save()
    }

    // MARK: - Recurring Rules

    /// Generates any missed transactions for each recurring rule since its
    /// `lastRun`. For every rule, intervals are walked forward from `startDate`
    /// (n = 1, 2, 3 …) until the computed date passes `Date.now`. Any interval
    /// date that falls after `lastRun` and on or before now produces a new
    /// `Transaction` tagged " (auto)", and `lastRun` is advanced to the most
    /// recent processed date. Walking from `startDate` and gating on `lastRun`
    /// means transactions generated on a previous launch are never duplicated.
    func processRecurringRules(context: ModelContext) {
        let rules = (try? context.fetch(FetchDescriptor<RecurringRule>())) ?? []
        // Guard: nothing to do when there are no rules.
        guard !rules.isEmpty else { return }

        let now = Date.now
        let calendar = Calendar.current
        let code = currencyCode

        for rule in rules {
            // Map the rule's frequency to a calendar component to step by.
            let component: Calendar.Component
            switch rule.frequency {
            case "weekly":  component = .weekOfYear
            case "monthly": component = .month
            case "yearly":  component = .year
            default: continue
            }

            var n = 1
            var mostRecentProcessed = rule.lastRun

            // Walk intervals forward until we step past now.
            while let intervalDate = calendar.date(byAdding: component, value: n, to: rule.startDate),
                  intervalDate <= now {
                // Only generate for intervals not already covered by lastRun.
                if intervalDate > rule.lastRun {
                    let transaction = Transaction(
                        type: rule.type,
                        amount: rule.amount,
                        currencyCode: code,
                        categoryId: rule.categoryId,
                        walletId: rule.walletId,
                        note: rule.note + " (auto)",
                        tags: [],
                        tripId: nil,
                        date: intervalDate,
                        fromRecurringId: rule.id
                    )
                    context.insert(transaction)
                    mostRecentProcessed = intervalDate
                }
                n += 1
            }

            rule.lastRun = mostRecentProcessed
        }

        try? context.save()

        // One-time migration marker. Once set, all rules have been processed up
        // to their lastRun at least once, so subsequent launches resume from the
        // advanced lastRun values rather than re-scanning historical intervals.
        UserDefaults.standard.set(true, forKey: Keys.recurringProcessorV1)
    }

    // MARK: - Formatting

    /// Formats a numeric amount with the active currency's symbol and placement.
    /// Display-only; no conversion is performed.
    func formatAmount(_ value: Double, code: String? = nil) -> String {
        let info = Self.currencyInfo(for: code ?? currencyCode)

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = info.code == "JPY" ? 0 : 2
        formatter.maximumFractionDigits = info.code == "JPY" ? 0 : 2
        let number = formatter.string(from: NSNumber(value: value)) ?? "0"

        return info.symbolBeforeAmount
            ? "\(info.symbol)\(number)"
            : "\(number) \(info.symbol)"
    }
}
