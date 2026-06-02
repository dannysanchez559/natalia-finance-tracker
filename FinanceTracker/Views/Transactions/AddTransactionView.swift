//
//  AddTransactionView.swift
//  Finna
//
//  Add/Edit transaction sheet. Phase 3 skeleton — placeholder content only.
//  (This is the first screen built for real in Phase 4.)
//

import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                Text("Add Transaction — placeholder")
                    .font(.appSerif(20))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AddTransactionView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
