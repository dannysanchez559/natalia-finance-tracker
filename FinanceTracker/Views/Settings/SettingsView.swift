//
//  SettingsView.swift
//  Finna
//
//  Appearance, currency, backup/restore, about.
//  Phase 4 screen 7 — functional settings.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    // Full model snapshots for export/backup and CSV id resolution.
    @Query private var transactions: [Transaction]
    @Query private var wallets: [Wallet]
    @Query private var categories: [AppCategory]
    @Query private var trips: [Trip]
    @Query private var goals: [SavingsGoal]
    @Query private var subscriptions: [Subscription]
    @Query private var recurringRules: [RecurringRule]

    @State private var showingCurrencyPicker = false

    // Export file URLs, regenerated each time the sheet appears.
    @State private var csvURL: URL?
    @State private var backupURL: URL?

    // Restore flow.
    @State private var showingImporter = false
    @State private var pendingBackup: BackupBundle?
    @State private var showingRestoreConfirm = false
    @State private var resultMessage: String?
    @State private var showingResultAlert = false

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            List {
                appearanceSection(store: store)
                currencySection
                dataSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.appSans(AppTheme.Typography.fontBody, weight: .semibold))
                }
            }
            .sheet(isPresented: $showingCurrencyPicker) {
                CurrencyPickerView()
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json]
            ) { result in
                handleImport(result)
            }
            .alert("Replace all data?", isPresented: $showingRestoreConfirm) {
                Button("Cancel", role: .cancel) { pendingBackup = nil }
                Button("Replace", role: .destructive) { performRestore() }
            } message: {
                Text("Restoring this backup will permanently delete all current transactions, wallets, categories, and plans, then replace them with the backup contents.")
            }
            .alert("Restore", isPresented: $showingResultAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resultMessage ?? "")
            }
            .onAppear(perform: regenerateExports)
        }
    }

    // MARK: - Section 1: Appearance

    private func appearanceSection(store: DataStore) -> some View {
        @Bindable var store = store
        return Section {
            Toggle(isOn: $store.isDarkMode) {
                Label {
                    Text("Dark mode")
                        .font(.appSans(AppTheme.Typography.fontBody))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                } icon: {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(AppTheme.Colors.accent)
                }
            }
            .tint(AppTheme.Colors.accent)
        } header: {
            sectionHeader("Appearance")
        }
    }

    // MARK: - Section 2: Currency

    private var currencySection: some View {
        Section {
            Button {
                showingCurrencyPicker = true
            } label: {
                HStack {
                    Label {
                        Text("Display currency")
                            .font(.appSans(AppTheme.Typography.fontBody))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                    } icon: {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundStyle(AppTheme.Colors.accent)
                    }
                    Spacer()
                    Text(store.currencyCode)
                        .font(.appSans(AppTheme.Typography.fontBody))
                        .foregroundStyle(AppTheme.Colors.textMuted)
                    Image(systemName: "chevron.right")
                        .font(.appSans(AppTheme.Typography.fontLabel, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textMuted)
                }
            }
        } header: {
            sectionHeader("Currency")
        }
    }

    // MARK: - Section 3: Data

    private var dataSection: some View {
        Section {
            if let csvURL {
                ShareLink(item: csvURL) {
                    dataRow(icon: "tablecells", label: "Export CSV")
                }
            }
            if let backupURL {
                ShareLink(item: backupURL) {
                    dataRow(icon: "arrow.up.doc", label: "Backup JSON")
                }
            }
            Button {
                showingImporter = true
            } label: {
                dataRow(icon: "arrow.down.doc", label: "Restore from Backup")
            }
        } header: {
            sectionHeader("Data")
        } footer: {
            Text("Export your transactions as a spreadsheet, or back up and restore your full database as a JSON file.")
                .font(.appSans(AppTheme.Typography.fontLabel))
                .foregroundStyle(AppTheme.Colors.textMuted)
        }
    }

    private func dataRow(icon: String, label: String) -> some View {
        Label {
            Text(label)
                .font(.appSans(AppTheme.Typography.fontBody))
                .foregroundStyle(AppTheme.Colors.textPrimary)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.Colors.accent)
        }
    }

    // MARK: - Section 4: About

    private var aboutSection: some View {
        Section {
            HStack {
                Label {
                    Text("Version")
                        .font(.appSans(AppTheme.Typography.fontBody))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                } icon: {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(AppTheme.Colors.accent)
                }
                Spacer()
                Text(versionString)
                    .font(.appSans(AppTheme.Typography.fontBody))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
        } header: {
            sectionHeader("About")
        }
    }

    private var versionString: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }

    // MARK: - Shared Header

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.appSans(AppTheme.Typography.fontCaption, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(AppTheme.Colors.textMuted)
    }

    // MARK: - Export Generation

    private func regenerateExports() {
        csvURL = makeCSVFile()
        backupURL = makeBackupFile()
    }

    /// Builds the CSV file and writes it to the temp directory. Returns nil on failure.
    private func makeCSVFile() -> URL? {
        let walletNames = Dictionary(uniqueKeysWithValues: wallets.map { ($0.id, $0.name) })
        let categoryLabels = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.label) })

        let isoFormatter = ISO8601DateFormatter()
        let header = "id,date,type,amount,currency,category,wallet,note,tags"

        let rows = transactions
            .sorted { $0.date > $1.date }
            .map { tx -> String in
                let fields = [
                    tx.id.uuidString,
                    isoFormatter.string(from: tx.date),
                    tx.type,
                    String(format: "%.2f", tx.amount),
                    tx.currencyCode,
                    categoryLabels[tx.categoryId] ?? tx.categoryId,
                    walletNames[tx.walletId] ?? tx.walletId,
                    tx.note,
                    tx.tags.joined(separator: ";"),
                ]
                return fields.map(csvEscape).joined(separator: ",")
            }

        let csv = ([header] + rows).joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("finna-transactions.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    /// Wraps a CSV field in quotes and escapes embedded quotes.
    private func csvEscape(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// Encodes the full database to a JSON file in the temp directory. Returns nil on failure.
    private func makeBackupFile() -> URL? {
        let bundle = BackupBundle(
            transactions: transactions.map(CodableTransaction.init),
            wallets: wallets.map(CodableWallet.init),
            categories: categories.map(CodableCategory.init),
            trips: trips.map(CodableTrip.init),
            goals: goals.map(CodableGoal.init),
            subscriptions: subscriptions.map(CodableSubscription.init),
            recurringRules: recurringRules.map(CodableRecurringRule.init)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("finna-backup.json")
        do {
            let data = try encoder.encode(bundle)
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Restore

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .failure(let error):
            resultMessage = "Could not open the file: \(error.localizedDescription)"
            showingResultAlert = true
        case .success(let url):
            let needsAccess = url.startAccessingSecurityScopedResource()
            defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                pendingBackup = try decoder.decode(BackupBundle.self, from: data)
                showingRestoreConfirm = true
            } catch {
                resultMessage = "This file is not a valid Finna backup."
                showingResultAlert = true
            }
        }
    }

    private func performRestore() {
        guard let backup = pendingBackup else { return }
        defer { pendingBackup = nil }

        do {
            // Wipe every existing record.
            try modelContext.delete(model: Transaction.self)
            try modelContext.delete(model: Wallet.self)
            try modelContext.delete(model: AppCategory.self)
            try modelContext.delete(model: Trip.self)
            try modelContext.delete(model: SavingsGoal.self)
            try modelContext.delete(model: Subscription.self)
            try modelContext.delete(model: RecurringRule.self)

            // Re-insert everything from the backup.
            backup.wallets.forEach { modelContext.insert($0.toModel()) }
            backup.categories.forEach { modelContext.insert($0.toModel()) }
            backup.trips.forEach { modelContext.insert($0.toModel()) }
            backup.goals.forEach { modelContext.insert($0.toModel()) }
            backup.subscriptions.forEach { modelContext.insert($0.toModel()) }
            backup.recurringRules.forEach { modelContext.insert($0.toModel()) }
            backup.transactions.forEach { modelContext.insert($0.toModel()) }

            try modelContext.save()
            regenerateExports()
            resultMessage = "Your data was restored successfully."
        } catch {
            resultMessage = "Restore failed: \(error.localizedDescription)"
        }
        showingResultAlert = true
    }
}

// MARK: - Backup Codable Mirrors

/// Single Codable container holding every model array for JSON backup/restore.
struct BackupBundle: Codable {
    var transactions: [CodableTransaction]
    var wallets: [CodableWallet]
    var categories: [CodableCategory]
    var trips: [CodableTrip]
    var goals: [CodableGoal]
    var subscriptions: [CodableSubscription]
    var recurringRules: [CodableRecurringRule]
}

struct CodableTransaction: Codable {
    var id: UUID
    var type: String
    var amount: Double
    var currencyCode: String
    var categoryId: String
    var walletId: String
    var note: String
    var tags: [String]
    var tripId: String?
    var date: Date
    var fromRecurringId: String?

    init(_ m: Transaction) {
        id = m.id; type = m.type; amount = m.amount; currencyCode = m.currencyCode
        categoryId = m.categoryId; walletId = m.walletId; note = m.note; tags = m.tags
        tripId = m.tripId; date = m.date; fromRecurringId = m.fromRecurringId
    }

    func toModel() -> Transaction {
        Transaction(id: id, type: type, amount: amount, currencyCode: currencyCode,
                    categoryId: categoryId, walletId: walletId, note: note, tags: tags,
                    tripId: tripId, date: date, fromRecurringId: fromRecurringId)
    }
}

struct CodableWallet: Codable {
    var id: String, name: String, emoji: String, colorHex: String, isDefault: Bool
    init(_ m: Wallet) { id = m.id; name = m.name; emoji = m.emoji; colorHex = m.colorHex; isDefault = m.isDefault }
    func toModel() -> Wallet { Wallet(id: id, name: name, emoji: emoji, colorHex: colorHex, isDefault: isDefault) }
}

struct CodableCategory: Codable {
    var id: String, label: String, emoji: String, colorHex: String, type: String, isDefault: Bool
    init(_ m: AppCategory) { id = m.id; label = m.label; emoji = m.emoji; colorHex = m.colorHex; type = m.type; isDefault = m.isDefault }
    func toModel() -> AppCategory { AppCategory(id: id, label: label, emoji: emoji, colorHex: colorHex, type: type, isDefault: isDefault) }
}

struct CodableTrip: Codable {
    var id: String, name: String, budget: Double, isActive: Bool
    init(_ m: Trip) { id = m.id; name = m.name; budget = m.budget; isActive = m.isActive }
    func toModel() -> Trip { Trip(id: id, name: name, budget: budget, isActive: isActive) }
}

struct CodableGoal: Codable {
    var id: String, name: String, target: Double, saved: Double, emoji: String
    init(_ m: SavingsGoal) { id = m.id; name = m.name; target = m.target; saved = m.saved; emoji = m.emoji }
    func toModel() -> SavingsGoal { SavingsGoal(id: id, name: name, target: target, saved: saved, emoji: emoji) }
}

struct CodableSubscription: Codable {
    var id: String, name: String, amount: Double, period: String, emoji: String
    init(_ m: Subscription) { id = m.id; name = m.name; amount = m.amount; period = m.period; emoji = m.emoji }
    func toModel() -> Subscription { Subscription(id: id, name: name, amount: amount, period: period, emoji: emoji) }
}

struct CodableRecurringRule: Codable {
    var id: String, type: String, amount: Double, categoryId: String, walletId: String
    var note: String, frequency: String, startDate: Date, lastRun: Date
    init(_ m: RecurringRule) {
        id = m.id; type = m.type; amount = m.amount; categoryId = m.categoryId; walletId = m.walletId
        note = m.note; frequency = m.frequency; startDate = m.startDate; lastRun = m.lastRun
    }
    func toModel() -> RecurringRule {
        RecurringRule(id: id, type: type, amount: amount, categoryId: categoryId, walletId: walletId,
                      note: note, frequency: frequency, startDate: startDate, lastRun: lastRun)
    }
}

#Preview {
    SettingsView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
