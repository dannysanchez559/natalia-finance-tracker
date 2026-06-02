//
//  Wallet.swift
//  Finna
//
//  A cash/card/savings account. Balance is derived from transactions, not stored.
//

import Foundation
import SwiftData

@Model
final class Wallet {
    @Attribute(.unique) var id: String
    var name: String
    var emoji: String
    var colorHex: String
    var isDefault: Bool

    init(
        id: String = UUID().uuidString,
        name: String = "",
        emoji: String = "💵",
        colorHex: String = "#7AC9A6",
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.isDefault = isDefault
    }
}
