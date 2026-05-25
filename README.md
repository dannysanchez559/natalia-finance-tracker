# Finance Tracker App

A personal finance tracking mobile app — currently built as a React web prototype, ready to be converted to a native iOS app for the App Store.

## Project Overview

This is a fully functional expense tracking app with the following features:
- Multi-currency support (14 currencies including USD, EUR, GBP, AED, RUB, JPY, etc.)
- Multiple wallets (Cash, Card, Savings, custom)
- Custom categories with emoji and color
- Monthly budgets with progress tracking and alerts
- Trip mode for tracking expenses during travel
- Savings goals with progress bars
- Subscription tracker (Netflix, Spotify, etc.)
- Recurring transactions (weekly/monthly/yearly auto-add)
- Calendar view with daily totals
- Pie chart statistics (week/month/year)
- Light/dark theme
- Search and filtering
- Tags
- CSV export
- Full JSON backup and restore
- Onboarding flow for new users
- Quick actions for frequent transactions

## Current State

- **Built as:** React (JSX) for web/Claude artifact environment
- **Storage:** Uses `window.storage` API (Claude's storage). Must be migrated to AsyncStorage or similar for native.
- **Styling:** Inline styles with Fraunces + system fonts
- **Icons:** lucide-react

## What I Need

Convert this React web app to a native iOS app and publish it to the Apple App Store.

### Required Tasks

1. **Port to React Native (Expo recommended)**
   - Replace HTML elements (`div`, `button`, `input`) with React Native equivalents (`View`, `Pressable`, `TextInput`)
   - Replace `window.storage` with `AsyncStorage` or `MMKV`
   - Adapt styling to React Native StyleSheet
   - Replace SVG pie chart with `react-native-svg` or `victory-native`
   - Use `expo-document-picker` and `expo-file-system` for backup/export functionality

2. **iOS-specific enhancements**
   - Face ID / Touch ID authentication on app open
   - Home screen widget showing balance + quick "Add expense" button
   - Local push notifications for budget alerts and recurring transactions
   - Haptic feedback on key actions
   - Proper Safe Area handling for notched devices

3. **App Store preparation**
   - App icon (1024x1024) — design or use provided concept
   - Screenshots for required iPhone sizes (6.7", 6.5", 5.5")
   - App Store description, keywords, category (Finance)
   - Privacy policy page
   - Age rating questionnaire

4. **Publishing**
   - Submit the build to App Store Connect
   - Handle the App Review feedback (typically 1–2 revisions)
   - Confirm successful App Store listing

## Files Included

- `App.jsx` — full React source code for the app (single file, ~1500 lines)
- `README.md` — this file

## Important Notes for the Developer

- The Apple Developer account ($99/year) **MUST be registered under the client's name and Apple ID**, not the developer's. The developer will be invited as a team member temporarily.
- The full source code must be delivered to the client (via GitHub repo or ZIP) along with build instructions.
- All app data is stored locally on the device. No backend, no servers, no bank integrations needed.
- The app does NOT collect personal data, does NOT have ads, does NOT have in-app purchases (for V1).

## Suggested Stack

- **Framework:** Expo (managed workflow) or bare React Native
- **Language:** TypeScript preferred but JavaScript acceptable
- **Storage:** `@react-native-async-storage/async-storage` or `react-native-mmkv`
- **Navigation:** React Navigation (bottom tabs)
- **Charts:** `react-native-svg` for pie chart, or `victory-native`
- **Icons:** `lucide-react-native`
- **Build & Publish:** EAS Build + EAS Submit (Expo) or Fastlane

## Budget & Timeline

Please provide your estimate for:
1. Conversion to React Native
2. iOS-specific features (Face ID, widget, notifications)
3. App Store assets and submission
4. Total timeline and cost

## Deliverables Expected

1. ✅ Full source code (GitHub repo)
2. ✅ TestFlight build for client to test before submission
3. ✅ App live on the App Store under client's developer account
4. ✅ Documentation on how to update and rebuild the app
5. ✅ 30 days of bug-fix support after App Store approval

## Design Reference

The app uses a warm, minimalist aesthetic:
- Dark theme: deep brown (`#1a1410`) + golden accent (`#d4a574`)
- Light theme: cream (`#faf6f0`) + bronze accent (`#b88a5a`)
- Serif typography (Fraunces) for numbers and titles
- Sans-serif (system) for body text
- Soft, rounded corners (12–20px radius)

Please preserve this aesthetic in the native version.

---

**Thank you for considering this project!**
# natalia-finance-tracker
