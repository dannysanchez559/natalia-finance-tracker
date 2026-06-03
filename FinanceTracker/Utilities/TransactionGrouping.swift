//
//  TransactionGrouping.swift
//  Finna
//
//  Shared helpers for grouping transactions into day sections (Today /
//  Yesterday / "12 Jun") and for deriving balances. Used by Home and
//  All Transactions so the two screens stay consistent.
//

import Foundation

/// A set of transactions that all fall on the same calendar day.
struct DayGroup: Identifiable {
    let id: Date          // start-of-day, also the sort key
    let label: String     // "Today" / "Yesterday" / "12 Jun"
    let transactions: [Transaction]
}

enum TransactionGrouping {

    /// Groups transactions by calendar day, newest day first and newest
    /// transaction first within each day.
    static func byDay(_ transactions: [Transaction], calendar: Calendar = .current) -> [DayGroup] {
        let buckets = Dictionary(grouping: transactions) { calendar.startOfDay(for: $0.date) }

        return buckets
            .sorted { $0.key > $1.key }
            .map { day, items in
                DayGroup(
                    id: day,
                    label: dayLabel(for: day, calendar: calendar),
                    transactions: items.sorted { $0.date > $1.date }
                )
            }
    }

    /// "Today" / "Yesterday" / "12 Jun" for a given day.
    static func dayLabel(for date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}

extension Array where Element == Transaction {

    /// Signed sum: income adds, expense subtracts. Used for wallet balances.
    var signedTotal: Double {
        reduce(0) { $0 + ($1.type == "income" ? $1.amount : -$1.amount) }
    }

    /// Total of just the income transactions.
    var incomeTotal: Double {
        filter { $0.type == "income" }.reduce(0) { $0 + $1.amount }
    }

    /// Total of just the expense transactions.
    var expenseTotal: Double {
        filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount }
    }

    /// All-time balance for a single wallet (income − expense).
    func balance(forWallet walletId: String) -> Double {
        filter { $0.walletId == walletId }.signedTotal
    }

    /// Transactions falling in the same calendar month + year as `reference`.
    func inMonth(of reference: Date = .now, calendar: Calendar = .current) -> [Transaction] {
        filter { calendar.isDate($0.date, equalTo: reference, toGranularity: .month) }
    }
}
