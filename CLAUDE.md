# CLAUDE.md — Finance Tracker iOS App

This file gives Claude Code the context it needs to work effectively on this project. Read this before making any changes.

---

## Project Summary

This is a native iOS personal finance tracking app being built in SwiftUI for the Apple App Store. It was originally prototyped as a React/JSX single-file web app (`App.jsx`) inside a Claude artifact environment. That prototype defines the complete feature set and is the source of truth for what the app should do.

The client is Natalia Zhyvopystseva. The developer is Daniel Sanchez. The contract is a fixed-price Upwork engagement: $5,000 USD across 2 milestones.

**Do not add features beyond what is in the prototype or the PRD. Scope is fixed.**

---

## Build Philosophy — How We Construct This App

We follow the same sequence a contractor uses to build a house. Every phase must be complete and stable before the next begins. Do not skip ahead.

```
Phase 1 — BLUEPRINTS      Models + DataStore + AppTheme (no UI at all)
Phase 2 — FOUNDATION      App entry point + tab shell + navigation skeleton
Phase 3 — FRAMING         All screens exist, all routes reachable, placeholder content only
Phase 4 — ROOMS           Feature logic built screen by screen, functional but unstyled
Phase 5 — FINISHING       UI polish, animations, haptics, empty states, edge cases
```

### What this means in practice

**Phase 1 — Blueprints (Data + Theme)**
Build all SwiftData models, DataStore with seed logic, and AppTheme constants. Zero UI. This must compile cleanly before any views are written. Everything downstream depends on this being correct.

**Phase 2 — Foundation (App Shell)**
`FinanceTrackerApp.swift`, `MainTabView.swift`, onboarding gate (UserDefaults check). The app launches, shows the tab bar, and each tab renders a `Text("placeholder")`. Nothing more.

**Phase 3 — Framing (Screen Skeletons)**
Every screen file exists. Every sheet and modal can be opened and dismissed. Navigation is fully wired. No real data, no real logic yet — just the scaffolding of every view with correct layout containers and placeholder text. The complete skeleton of the house.

**Phase 4 — Rooms (Feature Logic, Screen by Screen)**
Build one screen at a time, fully functional with real data before moving to the next. Order:
1. Add/Edit Transaction sheet (the most-used flow — everything depends on data existing)
2. Home screen (balance card, wallets, recent transactions)
3. All Transactions + Search
4. Stats (pie chart, budgets)
5. Calendar
6. Plans (Recurring, Trips, Goals, Subscriptions)
7. Settings (theme, currency, backup/restore)

Each screen is considered "done" when: data reads and writes correctly, all user actions work, and it does not crash. UI quality at this stage is functional, not polished.

**Phase 5 — Finishing Touches**
Only after all screens pass Phase 4:
- Visual polish (spacing, typography, colors refined)
- Animations and transitions
- Haptic feedback
- Empty states
- Edge cases and error handling
- Dark mode audit
- Safe area and device size testing

### Rules for Claude Code sessions

- Always state which Phase and which screen you are working on at the start of a response
- Never jump to Phase 5 work while Phase 4 screens are incomplete
- If a bug is found in an earlier phase during later work, fix it immediately before continuing
- Each phase should end with a clean Xcode build (zero errors, zero warnings if possible)
- Commit after each phase completes: `git commit -m "Phase X complete: [description]"`

---

## Tech Stack

| Layer | Choice |
|---|---|
| Language | Swift (no Objective-C) |
| UI | SwiftUI only — no UIKit unless absolutely unavoidable |
| Persistence | SwiftData (iOS 17+) for all models; UserDefaults for lightweight settings |
| Charts | Swift Charts (native) — no third-party chart libraries |
| Icons | SF Symbols — no third-party icon libraries |
| Minimum iOS | iOS 17 |
| No networking | Zero API calls, zero backend, zero analytics |

There is no package manager setup yet. Do not add any Swift Package Manager dependencies unless explicitly asked. The entire app should be buildable with zero external dependencies.

---

## Project Structure

```
FinanceTracker/
├── FinanceTrackerApp.swift
├── Models/
│   ├── Transaction.swift
│   ├── Wallet.swift
│   ├── AppCategory.swift
│   ├── Trip.swift
│   ├── SavingsGoal.swift
│   ├── Subscription.swift
│   └── RecurringRule.swift
├── Persistence/
│   └── DataStore.swift
├── Views/
│   ├── Onboarding/OnboardingView.swift
│   ├── Home/HomeView.swift
│   ├── Transactions/AddTransactionView.swift
│   ├── Stats/StatsView.swift
│   ├── Calendar/CalendarView.swift
│   ├── Plans/PlansView.swift
│   ├── AllTransactions/AllTransactionsView.swift
│   └── Settings/SettingsView.swift
├── Components/
│   ├── FloatingAddButton.swift
│   ├── CardView.swift
│   ├── PrimaryButton.swift
│   └── TransactionRowView.swift
└── Theme/
    └── AppTheme.swift
```

When creating new files, place them in the correct folder above. Do not create files in the project root unless they are config files.

---

## Data Models — Quick Reference

All models use `@Model` from SwiftData.

**Transaction** — core record  
`id: UUID, type: String, amount: Double, currencyCode: String, categoryId: String, walletId: String, note: String, tags: [String], tripId: String?, date: Date, fromRecurringId: String?`

**Wallet** — cash/card/savings accounts  
`id: String, name: String, emoji: String, colorHex: String, isDefault: Bool`

**AppCategory** — expense or income category  
`id: String, label: String, emoji: String, colorHex: String, type: String, isDefault: Bool`

**Trip** — travel expense tracking  
`id: String, name: String, budget: Double, isActive: Bool`

**SavingsGoal** — savings target with manual progress  
`id: String, name: String, target: Double, saved: Double, emoji: String`

**Subscription** — recurring subscription tracker  
`id: String, name: String, amount: Double, period: String, emoji: String`

**RecurringRule** — auto-generate transactions on schedule  
`id: String, type: String, amount: Double, categoryId: String, walletId: String, note: String, frequency: String, startDate: Date, lastRun: Date`

---

## Theme — Do Not Deviate

All colors must come from `AppTheme.swift`. Never hardcode color hex values elsewhere in the codebase.

**Design direction:** Professional pastel design — gradient hero card, soft pastel-tinted cards with SF Symbol icon badges, no emojis, generous whitespace.

**Light mode (primary):**
- Background: `#F8F9FF`
- Surface (cards): `#FFFFFF`
- Accent: `#4B6BCC`
- Accent alt: `#3A5AB8`
- Income: `#2E8E6E`
- Expense: `#B85450`
- Danger: `#C0392B`
- Text primary: `#1A1F3C`
- Text muted: `#6470A0`
- Text dim: `#9AA0C4`
- Border: `#E2E5F0`
- Border alt: `#D0D4EC`
- Hero card: `#5567BB` (balance card background)
- Hero card alt: `#4558AA` (inner elements on the hero card)

**Dark mode:**
- Background: `#0E0F1A`
- Surface (cards): `#161828`
- Accent: `#7B8FD4`
- Income: `#5AAAC8`
- Expense: `#D47878`
- Text primary: `#EEEEF8`
- Text muted: `#8888AA`
- Border: `#2A2D45`
- Border alt: `#363A58`

**Typography:** All SF Pro system font, no serif. Use weight and size contrast to create hierarchy. Balance numbers use .thin at 34pt. Amounts use .semibold at 17pt. Body uses .regular at 14pt. Section headers use .semibold at 10pt with wide tracking. Never use New York or Georgia.

**Corner radius constants:** small = 10, medium = 14, large = 20  
**Tab bar:** 5 tabs — Home, Stats, Calendar, Plans, All  
**Floating + button:** 56pt circle, accent color, fixed above tab bar

---

## Visual Language

The app uses a professional pastel visual language. The data models still store an
`emoji` field for backwards compatibility, but **emojis are never shown in the UI** —
all iconography is SF Symbols looked up by id.

- **No emojis in the UI.** All icons come from `Components/IconMap.swift`, which maps a
  category or wallet `id` to an SF Symbol name (`IconMap.symbol(forCategory:)` /
  `IconMap.symbol(forWallet:)`). IconMap normalizes the stored seed ids (e.g. `cat-food`,
  `wallet-cash`) so lookups work without changing the seed ids. The emoji field stays in
  the models but is no longer rendered.
- **Pastel-tinted cards.** Cards use one of six pastel fills from the `PastelStyle` enum
  (`AppTheme.swift`). A pastel is assigned to an item by its sort position with
  `IconMap.pastel(forIndex:)`, which cycles peach → lavender → mint → sky → rose → sand.
  Each `PastelStyle` exposes three colors: `fill` (card background tint), `badge` (the
  circle behind the SF Symbol), and `text` (the symbol/icon and accent text). All pastels
  have light and dark variants and resolve automatically for the current color scheme.
- **Hero card gradient.** The balance/hero card uses `AppTheme.Colors.heroGradient` — a
  diagonal sky-blue → brand blue-purple `LinearGradient`.

**The six pastels and their purpose:**

| Pastel | Role |
|---|---|
| Peach | Warm category (e.g. Food) accent tint |
| Lavender | Soft purple accent for cards/badges |
| Mint | Green/income-leaning accent tint |
| Sky | Blue accent tint |
| Rose | Pink accent tint |
| Sand | Gold/warm-neutral accent tint |

Pastels are assigned by index (sort order), not hardcoded per category, so any list of
items gets a varied, balanced spread of tints.

---

## Key Business Logic

### Wallet Balances
Wallet balance = all-time sum of income transactions minus all-time sum of expense transactions for that `walletId`. Not just the current month.

### Monthly Stats
Income, expenses, and balance on the home screen = current calendar month only (same month + year as today).

### Active Trip
Only one trip can be active at a time. Stored in `UserDefaults` as `"activeTripId": String`. When a trip is active, all new expense transactions are automatically assigned that `tripId`.

### Recurring Rules
On every app launch, iterate all `RecurringRule` records. For each rule, calculate intervals elapsed since `lastRun`. For each missed interval, create a new `Transaction` with `"(auto)"` appended to the note. Update `lastRun`. Frequencies: weekly (+7 days), monthly (+1 month), yearly (+1 year).

### Budget Limits
Stored in `UserDefaults` as `[String: Double]` — key is `categoryId`, value is monthly limit. Not in SwiftData.

### Quick Actions
Stored in `UserDefaults` as encoded `[QuickAction]` (max 6). A `QuickAction` has: `id, type, amount, categoryId, walletId, note`. Tapping one creates a new transaction with today's date and those fields.

### Default Seed Data
On first launch (when SwiftData store is empty), seed:
- Wallets: Cash 💵 `#7AC9A6`, Card 💳 `#7A9CC6`, Savings 🐷 `#D4A574` (all `isDefault: true`)
- Expense categories: Food 🍕 `#E07060`, Transport 🚌 `#7A9CC6`, Home 🏠 `#A67AC9`, Fun 🎬 `#C97AAF`, Health 💊 `#7AC9A6`, Shopping 🛍️ `#D4A574`, Travel ✈️ `#6AB4D4`, Other 📌 `#8A7A66`
- Income categories: Salary 💼 `#7A9C7A`, Freelance 💻 `#9AC97A`, Gift 🎁 `#C9B87A`, Investment 📈 `#7AC9B8`, Other ✨ `#B8A87A`

---

## Currency

14 supported currencies. Display only — no conversion math, no exchange rate API.

`USD $, EUR €, GBP £, AED AED, RUB ₽, JPY ¥, CNY ¥, KZT ₸, TRY ₺, INR ₹, CHF CHF, CAD C$, AUD A$, THB ฿`

Currency is a global setting stored in `UserDefaults "currencyCode"`. All amounts in the database are stored as plain `Double` with no currency attached (currency is cosmetic).

---

## What NOT to Do

- Do not add any networking, API calls, or URLSession code
- Do not add any analytics (Firebase, Mixpanel, etc.)
- Do not add any advertising SDKs
- Do not add bank account or Plaid integration — explicitly out of scope
- Do not use UIKit views unless a SwiftUI equivalent is impossible
- Do not use any third-party Swift packages without explicit approval
- Do not add in-app purchases or StoreKit — V1 is free with no paywall
- Do not modify the data models without updating this file
- Do not delete or rename existing files without updating the project structure above
- Do not add Android/React Native code — this is iOS SwiftUI only
- Do not hardcode strings that should come from AppTheme

---

## Coding Conventions

- Use `@Observable` (Swift 5.9 macro) for view models, not `ObservableObject`
- Use `@Query` in SwiftUI views for SwiftData fetches where possible
- Use `@Environment(\.modelContext)` for inserts/deletes
- Prefer computed properties over functions for derived UI values (e.g. `var monthlyIncome: Double`)
- Use `extension` to group related helpers on models rather than utility classes
- All views should be broken into subviews — no view body should exceed ~100 lines
- Name sheets and alerts clearly: `@State private var showingAddTransaction = false`
- Use `#Preview` macros for all views
- Format amounts using `NumberFormatter` — never manual string interpolation for currency display

---

## Prototype Reference

The original React prototype is at `App.jsx` in this project. When in doubt about how a feature should behave, refer to the prototype logic. Key mappings:

| React (prototype) | SwiftUI (native) |
|---|---|
| `window.storage.get/set` | SwiftData + UserDefaults |
| `useState` | `@State` |
| `useMemo` | `var` computed properties |
| `useEffect` on load | `.task` modifier or `.onAppear` |
| Inline styles | `AppTheme` constants + SwiftUI modifiers |
| `lucide-react` icons | SF Symbols |
| CSS `@keyframes` | SwiftUI `.animation()` + `.transition()` |
| Modal bottom sheets | `.sheet()` with `presentationDetents` |
| `localStorage` / `window.storage` | SwiftData / UserDefaults |

---

## Deliverables Checklist

Before Milestone 1 is complete:
- [ ] All features from PRD Section 4 are functional
- [ ] Light and dark mode both look correct
- [ ] App runs on a real iPhone via TestFlight (not just simulator)
- [ ] No crashes on any main user flow
- [ ] Recurring rule processor runs on launch

Before Milestone 2 is complete:
- [ ] All TestFlight bugs from client feedback are fixed
- [ ] App icon (all sizes) is in Assets.xcassets
- [ ] Screenshots are taken for all required iPhone sizes
- [ ] App Store listing copy is written (APP_STORE_METADATA.md)
- [ ] Privacy policy template is provided to client
- [ ] App is submitted and approved on the U.S. App Store
- [ ] Source code is delivered to client via GitHub or ZIP
- [ ] App Store submission walk-through call is completed
