//
//  AppCategory.swift
//  Finna
//
//  An expense or income category. `type` is "expense" or "income".
//

import Foundation
import SwiftData

@Model
final class AppCategory {
    @Attribute(.unique) var id: String
    var label: String
    var emoji: String
    var colorHex: String
    var type: String
    var isDefault: Bool

    init(
        id: String = UUID().uuidString,
        label: String = "",
        emoji: String = "📌",
        colorHex: String = "#8A7A66",
        type: String = "expense",
        isDefault: Bool = false
    ) {
        self.id = id
        self.label = label
        self.emoji = emoji
        self.colorHex = colorHex
        self.type = type
        self.isDefault = isDefault
    }
}
