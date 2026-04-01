# Next Implementation Prompt

**Last Updated**: March 28, 2026
**Launch Path**: M18 → M9.28 → M7.7

---

## Active Milestones

### M18 — Store-Aware Shopping + Recipe Attribution
See `docs/next-prompt-M18.md` for full implementation guidance.

---

## Completed (Recent)

### M16.9 — ML Model Retraining
COMPLETE (March 28, 2026). BiLSTM-CRF v2 deployed, parser fixes ported, 3 new test classes. PR #105 merged, build 91.

---

## Planned (Next Up)

### M9.28 — Remove Diagnostic Logging for Production

**Status**: PLANNED
**Estimated**: 1-2 hours

Strip DiagnosticLogger, DebugLogService, and CloudKitLogger output from Release builds. Determine what to keep behind `#if DEBUG` vs remove entirely.

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

- M10.4: Recipe import polish — history, telemetry (deferred post-launch; M10.4.0 attribution done in M18)
- M6: Testing Foundation (12-18h)
- M9 Remaining (~120h)
