//
//  MainTabView.swift
//  Finna
//
//  5-tab shell (Home, Stats, Calendar, Plans, All) with a floating add button
//  overlaid above the tab bar. The add button is hidden on the Plans tab.
//

import SwiftUI

struct MainTabView: View {

    enum Tab: Int, CaseIterable {
        case home, stats, calendar, plans, all
    }

    @State private var selectedTab: Tab = .home
    @State private var showingAddTransaction = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(Tab.home)

                StatsView()
                    .tabItem { Label("Stats", systemImage: "chart.pie.fill") }
                    .tag(Tab.stats)

                CalendarView()
                    .tabItem { Label("Calendar", systemImage: "calendar") }
                    .tag(Tab.calendar)

                PlansView()
                    .tabItem { Label("Plans", systemImage: "checklist") }
                    .tag(Tab.plans)

                AllTransactionsView()
                    .tabItem { Label("All", systemImage: "list.bullet") }
                    .tag(Tab.all)
            }

            // Floating add button — hidden on the Plans tab.
            if selectedTab != .plans {
                FloatingAddButton {
                    showingAddTransaction = true
                }
                .padding(.bottom, 60) // sits above the tab bar
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView(editing: nil)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    MainTabView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
