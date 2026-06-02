//
//  AllTransactionsView.swift
//  Finna
//
//  Full transaction history. Phase 3 skeleton — placeholder content only.
//

import SwiftUI

struct AllTransactionsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                Text("All Transactions — placeholder")
                    .font(.appSerif(20))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
            .navigationTitle("All")
        }
    }
}

#Preview {
    AllTransactionsView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
