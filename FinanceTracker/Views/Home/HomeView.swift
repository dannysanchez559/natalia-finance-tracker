//
//  HomeView.swift
//  Finna
//
//  Dashboard. Phase 3 skeleton — placeholder content only.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                Text("Home — placeholder")
                    .font(.appSerif(20))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
