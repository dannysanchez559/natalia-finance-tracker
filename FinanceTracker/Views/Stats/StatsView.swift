//
//  StatsView.swift
//  Finna
//
//  Spending breakdown + budgets. Phase 3 skeleton — placeholder content only.
//

import SwiftUI

struct StatsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                Text("Stats — placeholder")
                    .font(.appSerif(20))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
            .navigationTitle("Stats")
        }
    }
}

#Preview {
    StatsView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
