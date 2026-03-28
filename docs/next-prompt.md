# Next Implementation Prompt

**Last Updated**: March 27, 2026
**Launch Path**: M9.28 → M7.7 (paused)

---

## Active Milestones

### M16.9 — ML Model Retraining
See `docs/next-prompt-M16.9.md` for full implementation guidance.

---

## Planned (Next Up)

### M9.28 — Remove Diagnostic Logging for Production

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

### M7.7 — App Store Submission

**Status**: PLANNED
**Estimated**: 3-5h

Screenshots, metadata, App Store Connect configuration, privacy policy, review submission.

---

## Post-Launch Priorities

- M10.4: Polish & Integration (11-16h)
- M7.7: App Store Submission (3-5h)
- M6: Testing Foundation (20-30h)
- M9 Remaining (~120h)
