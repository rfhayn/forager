## Why

forager is feature-complete for v1 launch. All code work (M18 store-aware shopping, FUI-1 dashboard, M19 factory enforcement) is merged to main. Two things remain before App Store submission: (1) documentation and web assets required by App Store Connect (privacy policy update, landing page, App Store copy, README), and (2) M9.28 diagnostic logging strip so release builds don't write debug logs to disk or expose a diagnostics UI to users.

## What Changes

- **Update privacy policy** (`docs/privacy.html`) to disclose optional AI ingredient parsing via Anthropic's Claude API
- **Create landing page** (`docs/index.html`) for GitHub Pages root — provides Marketing URL for App Store Connect
- **Create app icon for web** (`docs/icon.png`) — 512px version of app icon for landing page
- **Rewrite README.md** with current stats (~345h, 531 tests, 13 entities, schema v11) and correct license (proprietary, not MIT)
- **Draft App Store listing copy** (`docs/app-store-listing.md`) — name, subtitle, description, keywords, plus manual ASC submission checklist
- **Gate diagnostic logging behind `#if DEBUG`** (M9.28) — DiagnosticLogger and DebugLogService write to disk and expose UI in Release builds; must be no-op in production

## Capabilities

### New Capabilities

- `app-store-assets`: Web presence and documentation required for App Store submission (privacy policy, landing page, README, App Store copy, submission checklist)

### Modified Capabilities

- `settings`: Gate diagnostics section behind `#if DEBUG` so it's hidden in Release builds

## Impact

- **Web/docs (4 files)**: `docs/privacy.html` (modify), `docs/index.html` (create), `docs/icon.png` (create), `docs/app-store-listing.md` (create)
- **README.md** (rewrite)
- **Services (3 files)**: `DiagnosticLogger.swift`, `DebugLogService.swift`, `CloudKitLogger.swift` — `#if DEBUG` gating
- **Views (1 file)**: `SettingsView.swift` — gate diagnostics section
- **No Core Data schema changes**
- **No API changes**
- **No new dependencies**
