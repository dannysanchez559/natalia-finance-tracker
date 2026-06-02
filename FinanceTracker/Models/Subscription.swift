//
//  Subscription.swift
//  Finna
//
//  A recurring subscription tracker. `period` is "monthly" or "yearly".
//

import Foundation
import SwiftData

@Model
final class Subscription {
    @Attribute(.unique) var id: String
    var name: String
    var amount: Double
    var period: String
    var emoji: String

    init(
        id: String = UUID().uuidString,
        name: String = "",
        amount: Double = 0,
        period: String = "monthly",
        emoji: String = "🔁"
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.period = period
        self.emoji = emoji
    }
}
