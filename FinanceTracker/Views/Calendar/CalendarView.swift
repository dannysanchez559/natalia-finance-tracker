//
//  CalendarView.swift
//  Finna
//
//  Month grid of daily transaction totals. Phase 3 skeleton — placeholder only.
//

import SwiftUI

struct CalendarView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                Text("Calendar — placeholder")
                    .font(.appSerif(20))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
            .navigationTitle("Calendar")
        }
    }
}

#Preview {
    CalendarView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
