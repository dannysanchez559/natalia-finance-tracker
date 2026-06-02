//
//  PlansView.swift
//  Finna
//
//  Recurring, Trips, Savings Goals, Subscriptions.
//  Phase 3 skeleton — placeholder content only.
//

import SwiftUI

struct PlansView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                Text("Plans — placeholder")
                    .font(.appSerif(20))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
            .navigationTitle("Plans")
        }
    }
}

#Preview {
    PlansView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
