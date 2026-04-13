## 1. Privacy Policy Update

- [x] 1.1 Update `docs/privacy.html` — add AI-Powered Ingredient Parsing subsection under Third-Party Services (OFF by default, user provides own key, only ingredient text sent, link to Anthropic privacy policy)
- [x] 1.2 Revise "no third parties" language to "except in the following cases, all of which you control" and add Anthropic as third bullet
- [x] 1.3 Bump "Last updated" from January 2026 to April 2026 (both occurrences: line 39 and line 192)

## 2. Landing Page

- [x] 2.1 Copy and resize app icon: `sips -Z 512` from `forager/Assets.xcassets/AppIcon.appiconset/forager-icon-light.png` to `docs/icon.png`
- [x] 2.2 Create `docs/index.html` — hero (icon, "forager", "Smart Meal Planner"), 6 feature bullets, TestFlight CTA (`https://testflight.apple.com/join/zwFHTpDs`), links (privacy, support, GitHub), footer. Match `privacy.html` aesthetic. Under 120 lines, no JS.

## 3. README Rewrite

- [x] 3.1 Rewrite `README.md` with corrected stats (~345h, 531 tests, 13 entities, schema v11, iOS 26+, 14 ADRs), proprietary license, TestFlight link, updated milestone table through M19

## 4. App Store Listing Copy

- [x] 4.1 Create `docs/app-store-listing.md` — Part A: metadata drafts (name, subtitle, description, keywords, category, copyright, URLs)
- [x] 4.2 Add Part B: ASC submission checklist (screenshots guidance, nutrition label answers, age rating, pricing, review notes, build selection, submission steps)

## 5. M9.28 — Strip Diagnostic Logging

- [x] 5.1 Gate `Services/DiagnosticLogger.swift` — wrap full class in `#if DEBUG`, add `#else` no-op stub with same API surface
- [x] 5.2 Gate `Services/DebugLogService.swift` — same pattern: `#if DEBUG` full impl, `#else` no-op stub
- [x] 5.3 Gate CloudKitLogger bridge — wrap `persist()` body in `Services/Persistence/CloudKitLogger.swift` with `#if DEBUG`
- [x] 5.4 Gate Settings diagnostics section — wrap `diagnosticLogSection` in `forager/Views/Settings/SettingsView.swift` with `#if DEBUG`

## 6. Build Verification

- [x] 6.1 Build Debug configuration — confirm zero errors, logging works
- [x] 6.2 Build Release configuration — confirm zero errors, no DiagnosticLogger file I/O references
