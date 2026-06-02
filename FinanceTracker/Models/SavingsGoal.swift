//
//  SavingsGoal.swift
//  Finna
//
//  A savings target with manually-updated progress.
//

import Foundation
import SwiftData

@Model
final class SavingsGoal {
    @Attribute(.unique) var id: String
    var name: String
    var target: Double
    var saved: Double
    var emoji: String

    init(
        id: String = UUID().uuidString,
        name: String = "",
        target: Double = 0,
        saved: Double = 0,
        emoji: String = "🎯"
    ) {
        self.id = id
        self.name = name
        self.target = target
        self.saved = saved
        self.emoji = emoji
    }
}
