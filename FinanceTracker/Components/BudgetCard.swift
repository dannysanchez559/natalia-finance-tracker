//
//  BudgetCard.swift
//  Finna
//
//  A pastel tile for the budgets grid: category icon badge, label, the amount
//  spent, the limit, and a thin progress bar. The pastel is chosen by the
//  category's position in the grid (index). Spent/limit are passed in.
//

import SwiftUI

struct BudgetCard: View {
    @Environment(DataStore.self) private var store

    var category: AppCategory
    var spent: Double
    var limit: Double
    var index: Int

    private var pastel: PastelStyle { IconMap.pastel(forIndex: index) }

    private var ratio: CGFloat {
        guard limit > 0 else { return 0 }
        return min(max(CGFloat(spent / limit), 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            IconBadge(symbol: IconMap.symbol(forCategory: category.id), style: pastel, size: 36)

            Text(category.label)
                .font(.appSans(AppTheme.Typography.fontLabel, weight: .semibold))
                .foregroundStyle(pastel.text)
                .lineLimit(1)

            Text(store.formatAmount(spent))
                .font(.appSans(AppTheme.Typography.fontCardNumber, weight: .semibold))
                .foregroundStyle(pastel.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("of \(store.formatAmount(limit))")
                .font(.appSans(AppTheme.Typography.fontCaption, weight: .regular))
                .foregroundStyle(pastel.text.opacity(0.7))
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(pastel.text.opacity(0.15))
                    Capsule()
                        .fill(pastel.text)
                        .frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(pastel.fill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    let cat = AppCategory(id: "cat-food", label: "Food", emoji: "🍕", colorHex: "#E07060")
    return BudgetCard(category: cat, spent: 340, limit: 500, index: 0)
        .environment(DataStore())
        .frame(width: 170)
        .padding()
        .background(AppTheme.Colors.background)
}
