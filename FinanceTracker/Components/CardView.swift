//
//  CardView.swift
//  Finna
//
//  Generic surface container that wraps arbitrary content in the standard
//  card treatment. (Stub — content layout expanded in later phases.)
//

import SwiftUI

struct CardView<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    CardView {
        Text("Card content")
            .foregroundStyle(AppTheme.Colors.textPrimary)
    }
    .padding()
    .background(AppTheme.Colors.background)
}
