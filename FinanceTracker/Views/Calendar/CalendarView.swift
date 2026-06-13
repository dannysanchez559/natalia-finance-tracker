//
//  CalendarView.swift
//  Finna
//
//  Month grid of daily activity. The displayed month is driven by a @State
//  Date pinned to the first of the month; chevrons step it forward and back.
//  Days with transactions show an accent dot; tapping a day fills the detail
//  card below with that day's transactions. All transactions are fetched once
//  with @Query and filtered in computed properties — cells never query.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(DataStore.self) private var store

    @Query private var transactions: [Transaction]
    @Query private var wallets: [Wallet]
    @Query private var categories: [AppCategory]

    // First day of the month currently on screen.
    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: .now)
    // The day whose transactions fill the detail card. Defaults to today.
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: .now)

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.xs),
                                count: 7)

    // MARK: - Lookups

    private var categoryById: [String: AppCategory] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }
    private var walletById: [String: Wallet] {
        Dictionary(uniqueKeysWithValues: wallets.map { ($0.id, $0) })
    }

    // Start-of-day dates within the displayed month that have at least one
    // transaction — the source for the cell dot indicators.
    private var activeDays: Set<Date> {
        var days: Set<Date> = []
        for tx in transactions where calendar.isDate(tx.date, equalTo: displayedMonth, toGranularity: .month) {
            days.insert(calendar.startOfDay(for: tx.date))
        }
        return days
    }

    // Transactions on the selected day, newest first.
    private var selectedTransactions: [Transaction] {
        transactions
            .filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Grid model

    // Leading empty slots so the 1st lands under the correct weekday, with the
    // grid fixed to a Monday-first week regardless of the device's locale.
    private var leadingEmptyCount: Int {
        let weekday = calendar.component(.weekday, from: displayedMonth) // 1 = Sun
        return (weekday + 5) % 7
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
    }

    // One entry per grid cell: nil for the leading padding, otherwise a date.
    private var gridCells: [Date?] {
        let leading = [Date?](repeating: nil, count: leadingEmptyCount)
        let days: [Date?] = (0..<daysInMonth).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: displayedMonth)
        }
        return leading + days
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var selectedDayTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: selectedDate)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    monthHeader
                    VStack(spacing: AppTheme.Spacing.sm) {
                        weekdayRow
                        dayGrid
                    }
                    detailCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                // Clears the floating + button (56pt) and the tab bar.
                Color.clear.frame(height: 100)
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button { step(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
            }

            Spacer()

            Text(monthTitle)
                .font(.appSerif(AppTheme.Typography.fontTitle, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            Button { step(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
            }
        }
    }

    // MARK: - Weekday Row

    private var weekdayRow: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                Text(day)
                    .font(.appSans(AppTheme.Typography.fontCaption, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textMuted)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Day Grid

    private var dayGrid: some View {
        LazyVGrid(columns: columns, spacing: AppTheme.Spacing.xs) {
            ForEach(Array(gridCells.enumerated()), id: \.offset) { _, date in
                if let date {
                    dayCell(date)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let hasActivity = activeDays.contains(calendar.startOfDay(for: date))

        return Button {
            selectedDate = calendar.startOfDay(for: date)
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.appSans(AppTheme.Typography.fontLabel, weight: isToday ? .semibold : .regular))
                    .foregroundStyle(dayTextColor(isSelected: isSelected, isToday: isToday))
                Circle()
                    .fill(isSelected ? AppTheme.Colors.surface : AppTheme.Colors.accent)
                    .frame(width: 5, height: 5)
                    .opacity(hasActivity ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(cellBackground(isSelected: isSelected, isToday: isToday))
        }
        .buttonStyle(.plain)
    }

    private func dayTextColor(isSelected: Bool, isToday: Bool) -> Color {
        if isSelected { return .white }
        if isToday { return AppTheme.Colors.accent }
        return AppTheme.Colors.textPrimary
    }

    @ViewBuilder
    private func cellBackground(isSelected: Bool, isToday: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous)
                .fill(AppTheme.Colors.accent)
        } else if isToday {
            RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous)
                .fill(AppTheme.Colors.accent.opacity(0.12))
        }
    }

    // MARK: - Detail Card

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text(selectedDayTitle.uppercased())
                .font(.appSans(AppTheme.Typography.fontLabel, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textMuted)

            if selectedTransactions.isEmpty {
                emptyState
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(selectedTransactions) { tx in
                        TransactionRowView(
                            transaction: tx,
                            category: categoryById[tx.categoryId],
                            wallet: walletById[tx.walletId]
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: AppTheme.Spacing.md)
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "calendar")
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.Colors.textMuted.opacity(0.5))
            Text("No transactions on this day")
                .font(.appSans(AppTheme.Typography.fontBody))
                .foregroundStyle(AppTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.lg)
    }

    // MARK: - Actions

    private func step(by months: Int) {
        guard let next = calendar.date(byAdding: .month, value: months, to: displayedMonth) else { return }
        displayedMonth = calendar.startOfMonth(for: next)
    }
}

// MARK: - Calendar Helper

extension Calendar {
    /// The first day of the month containing `date`, at midnight.
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? startOfDay(for: date)
    }
}

#Preview {
    CalendarView()
        .environment(DataStore())
        .modelContainer(DataStore.modelContainer)
}
