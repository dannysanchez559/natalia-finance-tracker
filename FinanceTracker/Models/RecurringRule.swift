//
//  RecurringRule.swift
//  Finna
//
//  Auto-generates transactions on a schedule. `frequency` is
//  "weekly", "monthly", or "yearly". Processed on every app launch.
//

import Foundation
import SwiftData

@Model
final class RecurringRule {
    @Attribute(.unique) var id: String
    var type: String
    var amount: Double
    var categoryId: String
    var walletId: String
    var note: String
    var frequency: String
    var startDate: Date
    var lastRun: Date

    init(
        id: String = UUID().uuidString,
        type: String = "expense",
        amount: Double = 0,
        categoryId: String = "",
        walletId: String = "",
        note: String = "",
        frequency: String = "monthly",
        startDate: Date = .now,
        lastRun: Date = .now
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.categoryId = categoryId
        self.walletId = walletId
        self.note = note
        self.frequency = frequency
        self.startDate = startDate
        self.lastRun = lastRun
    }
}
