//
//  FinanceTrackerApp.swift
//  Finna
//
//  App entry point. Installs the shared SwiftData container and DataStore.
//

import SwiftUI
import SwiftData

@main
struct FinanceTrackerApp: App {
    @State private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
        .modelContainer(DataStore.modelContainer)
    }
}
