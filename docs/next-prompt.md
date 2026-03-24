# Next Implementation Prompt

**Last Updated**: March 23, 2026
**For Milestone**: Launch Path
**Status**: **M9.34 ✅** | **M9.33 ✅** | **M9.32 ✅** | **M9.31 ✅** | **M9.30 ✅** | **M9.29 ✅** | **M9.27 ✅** | **M9.26 ✅** | **M9.24 ✅** | **M9.15.3 ✅** | **M17.1 ✅** | **M10.6.5 ✅**

**Launch Path**: M9.28 → M7.7 (~4-7h to App Store)

---

## M9.28 — Remove Diagnostic Logging for Production

**Status**: PLANNED
**Estimated**: 1-2 hours

Strip DiagnosticLogger, DebugLogService, and CloudKitLogger output from Release builds. Determine what to keep behind `#if DEBUG` vs remove entirely. The diagnostic logging was invaluable during M9.15-M9.31 debugging but should not ship in the App Store build.

Key files to audit:
- `Services/DiagnosticLogger.swift` — the main logger
- `Services/CloudKitLogger.swift` — CloudKit-specific logging
- `Services/DebugLogService.swift` — debug log service
- All `diag.info/warning/error` calls in HouseholdService.swift
- Settings > Diagnostics section — may need to be hidden or removed

---

## M7.7 — App Store Submission

**Status**: PLANNED
**Estimated**: 3-5h

Screenshots, metadata, App Store Connect configuration, privacy policy, review submission.

---

## Recently Completed (This Session — March 21-23, 2026)

**29 builds shipped (59-87), 16 PRs (#86-101)**

| Milestone | What |
|-----------|------|
| M9.24 | Member import store routing (scope-aware assignment) |
| M9.25/25.1 | Glass card UI unification + grocery styling |
| M9.26 | Bug fixes x4 (cards, tap targets, favorites, names, calendar) |
| M9.27 | Welcome walkthrough redesign (3-screen carousel) |
| M9.29 | Claude/AI branding cleanup (sparkle icons) |
| M9.30 | Household security (schema v10, encryption, expiry, caps) |
| M9.31 | Ghost detection resilience (4-layer protection) |
| M9.32 | Grocery item name cleanup (clean names for aggregation) |
| M9.33 | AI multi-ingredient splitting (auto-split + indicators) |
| M9.34 | Import guide walkthrough (5-step coach marks) |
| M10.6.5 | Claude API documentation complete |
| M17.1 | Doc slimming 91% + PRD archival |

---

## Post-Launch Priorities

- M10.4: Polish & Integration (11-16h)
- M7.7: App Store Submission (3-5h)
- M6: Testing Foundation (20-30h)
- M9 Remaining (~120h)
