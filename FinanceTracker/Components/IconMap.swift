//
//  IconMap.swift
//  Finna
//
//  Central lookup from category/wallet ids to SF Symbol names, plus pastel
//  assignment by sort index. Per the Visual Language in CLAUDE.md, the UI shows
//  SF Symbols — never the stored emoji — and tints cards with pastel styles.
//

import Foundation

/// Maps domain ids to SF Symbol names and pastel styles.
///
/// The seed ids are stored with `cat-` / `wallet-` prefixes (e.g. `cat-food`,
/// `wallet-cash`) and a few Swift-side spellings differ from the original
/// prototype keys (`shopping` vs `shop`, `investment` vs `invest`,
/// `other-exp`/`other-inc` vs `other_e`/`other_i`). `normalize(_:)` reconciles
/// both forms so lookups work against the real seed ids without changing them.
struct IconMap {

    /// SF Symbol for a category id. Falls back to `circle.fill` for unknown ids.
    static func symbol(forCategory id: String) -> String {
        switch normalize(id) {
        case "food":      return "fork.knife"
        case "transport": return "bus"
        case "home":      return "house.fill"
        case "fun":       return "film"
        case "health":    return "cross.case.fill"
        case "shop":      return "bag.fill"
        case "travel":    return "airplane"
        case "other_e":   return "tag.fill"
        case "salary":    return "briefcase.fill"
        case "freelance": return "laptopcomputer"
        case "gift":      return "gift.fill"
        case "invest":    return "chart.line.uptrend.xyaxis"
        case "other_i":   return "sparkles"
        default:          return "circle.fill"
        }
    }

    /// SF Symbol for a wallet id. Falls back to `wallet.pass.fill` for unknown ids.
    static func symbol(forWallet id: String) -> String {
        switch normalize(id) {
        case "cash":    return "banknote.fill"
        case "card":    return "creditcard.fill"
        case "savings": return "building.columns.fill"
        default:        return "wallet.pass.fill"
        }
    }

    /// Cycles through the six pastels by index, so items get varied tints based
    /// on their position in a sorted list. Order: peach, lavender, mint, sky,
    /// rose, sand.
    static func pastel(forIndex index: Int) -> PastelStyle {
        let order: [PastelStyle] = [.peach, .lavender, .mint, .sky, .rose, .sand]
        let i = ((index % order.count) + order.count) % order.count
        return order[i]
    }

    /// Stable pastel for a category. The seed categories have no stored sort
    /// order, so we derive a fixed index from their canonical key ordering —
    /// each default category always gets the same tint. Custom categories fall
    /// back to a stable (launch-independent) hash of the id.
    static func pastel(forCategory id: String) -> PastelStyle {
        pastel(forIndex: categoryIndex(id))
    }

    // MARK: - Helpers

    /// Canonical ordering of the default seed categories, used to assign a
    /// deterministic pastel index per category.
    private static func categoryIndex(_ id: String) -> Int {
        let order = ["food", "transport", "home", "fun", "health", "shop",
                     "travel", "other_e", "salary", "freelance", "gift",
                     "invest", "other_i"]
        let key = normalize(id)
        if let i = order.firstIndex(of: key) { return i }
        // Stable fallback for user-created categories (hashValue is randomized
        // per launch, so sum the scalars instead).
        return key.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
    }

    /// Strips the `cat-`/`wallet-` seed prefix and maps Swift-side spellings onto
    /// the canonical lookup keys above.
    private static func normalize(_ id: String) -> String {
        var key = id
        if key.hasPrefix("cat-") { key.removeFirst("cat-".count) }
        if key.hasPrefix("wallet-") { key.removeFirst("wallet-".count) }

        switch key {
        case "shopping":  return "shop"
        case "investment": return "invest"
        case "other-exp": return "other_e"
        case "other-inc": return "other_i"
        default:          return key
        }
    }
}
