//
//  Trip.swift
//  Finna
//
//  Travel expense tracking. Only one trip may be active at a time
//  (active trip id is stored in UserDefaults, not here).
//

import Foundation
import SwiftData

@Model
final class Trip {
    @Attribute(.unique) var id: String
    var name: String
    var budget: Double
    var isActive: Bool

    init(
        id: String = UUID().uuidString,
        name: String = "",
        budget: Double = 0,
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.budget = budget
        self.isActive = isActive
    }
}
