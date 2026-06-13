//
//  MainTabView.swift
//  Finna
//
//  App shell. A custom bottom tab bar (CustomTabBar) drives a ZStack of the
//  five destination screens, with the floating add button overlaid above the
//  bar. The system TabView is no longer used. Each destination owns its own
//  NavigationStack and hides the system tab bar.
//

import SwiftUI

struct MainTabView: View {

    // 0: Home, 1: Stats, 2: Calendar, 3: Plans, 4: All
    @State private var selectedTab: Int = 0
    @State private var showingAddTransaction = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Active destination — each screen already provides its own
            // NavigationStack, so no extra wrapping is needed here.
            destinationView
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating add button — hidden on the Plans tab (index 3).
            if selectedTab != 3 {
                FloatingAddButton {
                    showingAddTransaction = true
                }
                .padding(.bottom, 90) // sits above the custom tab bar
            }

            // Custom tab bar pinned to the bottom; Spacer pushes content up.
            VStack(spacing: 0) {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView(editing: nil)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var destinationView: some View {
        switch selectedTab {
        case 0:
            HomeView()
                .toolbar(.hidden, for: .tabBar)
        case 1:
            StatsView()
                .toolbar(.hidden, for: .tabBar)
        case 2:
            CalendarView()
                .toolbar(.hidden, for: .tabBar)
        case 3:
            PlansView()
                .toolbar(.hidden, for: .tabBar)
        default:
            AllTransactionsView()
                .toolbar(.hidden, for: .tabBar)
        }
    }
}

#Preview {
    MainTabView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
