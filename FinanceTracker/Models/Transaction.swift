//
//  Transaction.swift
//  Finna
//
//  Core financial record. `type` is "income" or "expense".
//

import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var type: String
    var amount: Double
    var currencyCode: String
    var categoryId: String
    var walletId: String
    var note: String
    var tags: [String]
    var tripId: String?
    var date: Date
    var fromRecurringId: String?

    init(
        id: UUID = UUID(),
        type: String = "expense",
        amount: Double = 0,
        currencyCode: String = "USD",
        categoryId: String = "",
        walletId: String = "",
        note: String = "",
        tags: [String] = [],
        tripId: String? = nil,
        date: Date = .now,
        fromRecurringId: String? = nil
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.currencyCode = currencyCode
        self.categoryId = categoryId
        self.walletId = walletId
        self.note = note
        self.tags = tags
        self.tripId = tripId
        self.date = date
        self.fromRecurringId = fromRecurringId
    }
}
