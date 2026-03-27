# Next Implementation Prompt

**Last Updated**: March 26, 2026
**For Milestone**: M16 — Parsing Test Harness
**Status**: **M16.9 ACTIVE** | **M16.7 ✅** | **M16.8 ✅** | **M16.1-M16.6 ✅**

**Current**: M16 (parsing test harness) | **Launch Path**: M9.28 → M7.7 (paused)

---

## M16.9 — Two-Tier Comparison Logic (ACTIVE)

**What**: Implement Option C comparison in `ResultComparer.swift` — "core agreement" (AI canonical name found within local name) + "full agreement" (exact match). This separates descriptor differences from real parsing bugs.

**Why**: First run showed 37.3% agreement which was misleading. ~284 of 351 "mismatches" were descriptor differences (local: "small onion, diced" vs AI: "onion"), not bugs. The exact-match logic buried 7 real parser bugs under false positives.

**Before state** (newsletter snapshot):
- 42 recipes, 560 ingredients, 37.3% agreement
- 284 name mismatches (mostly descriptor diffs), 44 unit, 38 qty
- 213 classified "local likely wrong" (most weren't)

**What to implement**:
1. Update `ResultComparer.swift` — add `core_match` agreement level, containment-based name matching
2. Update `ReportGenerator.swift` — show both core and full agreement in report
3. Rerun harness with `--rerun-last` to get "after" numbers
4. Replenish seed URL list (many 404s reduced pool to ~42 healthy URLs)

**File**: `Tools/ParsingTestHarness/Sources/Harness/ResultComparer.swift`

---

## M16 — Completed Sub-Milestones

| Sub | Description | Status |
|-----|-------------|--------|
| M16.1-M16.6 | Harness build (scaffold, fetch, parse, compare, CLI) | ✅ |
| M16.7 | First loop: 7 parser bug fixes | ✅ |
| M16.8 | ML training data collection + retraining PRD | ✅ |

### Key Context for Next Session
- Harness at `Tools/ParsingTestHarness/`, run with `bash Tools/ParsingTestHarness/run-harness.sh`
- Parser copies in `Tools/ParsingTestHarness/Sources/Parsing/` — app code untouched
- API key needed for AI comparison: `ANTHROPIC_API_KEY=sk-... swift run ParsingHarness`
- Run results + logs in `Results/` (gitignored)
- 514 ML training data entries accumulated in `Results/training-data.json`
- Seed URL list at `Data/recipe-urls.json` — needs replenishing (many 404s)
- PRDs: `docs/prds/active/m16-parsing-test-harness.md`, `docs/prds/active/m16.9-ml-model-retraining.md`

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
