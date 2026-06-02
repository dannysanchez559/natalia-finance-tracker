//
//  ContentView.swift
//  Finna
//
//  Root gate: shows onboarding on first launch, otherwise the main tab shell.
//  Runs first-launch seeding and recurring-rule processing on appear.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    // Local mirror so the view re-renders when onboarding state flips.
    @State private var hasOnboarded = false

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView(onFinish: completeOnboarding)
            }
        }
        .preferredColorScheme(store.isDarkMode ? .dark : .light)
        .tint(AppTheme.Colors.accent)
        .task {
            store.seedIfNeeded(context: modelContext)
            store.processRecurringRules(context: modelContext)
            hasOnboarded = store.hasOnboarded
        }
    }

    private func completeOnboarding() {
        store.hasOnboarded = true
        hasOnboarded = true
    }
}

#Preview {
    ContentView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
