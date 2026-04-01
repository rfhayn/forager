# Current Development Story

**Last Updated**: April 1, 2026
**Status**: **M18 ACTIVE** | **FUI-1 ACTIVE** | **M16.9 COMPLETE**
**Total Progress**: ~320 hours
**Current Branch**: `feature/M18-store-aware-shopping`
**Launch Path**: M18 (remaining) → FUI-1 → M9.28 → M7.7

---

## LAUNCH PATH

| Milestone | Description | Est. Hours | Status |
|-----------|-------------|-----------|--------|
| **M9.24** | Member device import -> shared store routing | 0.5h | COMPLETE (PR #89, build 62 confirmed) |
| **M9.15.3** | Returning user detection after reinstall | 1h | COMPLETE (build 62, 6s discovery) |
| **M9.30** | Household invitation security hardening | 3-5h | COMPLETE (~3h, PR #96-97) |
| **M9.31** | CKShare acceptance resilience | 2-3h | COMPLETE (~1h, PR #97) |
| **M9.32** | Grocery item name cleanup | 1-2h | COMPLETE (~1h, PR #100) |
| **M9.33** | AI multi-ingredient splitting | 3-4h | COMPLETE (~3h, PR #100) |
| **M9.34** | First import guide walkthrough | 2-3h | COMPLETE (~2h, PR #101) |
| **M9.26** | Launch prep bug fixes (rounds 2-4) | 2-4h | COMPLETE (PRs #94-99) |
| **M18** | Store-aware shopping + recipe attribution (schema v11) | 7-10h | ACTIVE (4/6 subs complete) |
| **FUI-1** | Dashboard, navigation restructuring, recipe UI | 12-15h | PLANNED |
| **M9.28** | Remove diagnostic logging for production | 1-2h | PLANNED |
| **M7.7** | App Store submission | 3-5h | PLANNED |

---

## EXECUTION PLAN (Phases with Parallelism)

### Phase 1 — M18 remaining + FUI-1 recipe UI (parallel streams)

```
Worker A: M18.1.3 (1.75h) → M18.1.4 (1.75h)         Store UI
Worker B: FUI-1.5 (0.5h) → FUI-1.4 (1.5h) → FUI-1.1 (1h) → FUI-1.2 (2.5h) → FUI-1.3 (0.5h)
Worker C: FUI-1.6 (2.5h) after FUI-1.5 commits       Recipe grid toggle
```

No file conflicts between M18 and FUI-1 streams. FUI-1.6 depends on FUI-1.5 (computed properties).

### Phase 2 — Dashboard + logging cleanup (parallel streams)

```
Worker D: FUI-1.7 (4.5h)    Dashboard — needs FUI-1.1 + FUI-1.3 done
Worker E: M9.28 (1.5h)      Strip diagnostic logging — needs M18.1.3 done (SettingsView conflict)
```

### Phase 3 — PR + merge

Merge M18 feature branch (all M18 + FUI-1 + M9.28 work).

### Phase 4 — App Store (last, partly manual)

```
M7.7.1 (1-2h) Landing page + M7.7.2 (0.5h) README — can parallel
M7.7.3 (1-2h) App Store listing — needs final build for screenshots
M7.7.4 (0.5h) Submit for review
```

**Wall-clock estimate with parallelism**: ~12-15h | **Sequential**: ~22-27h

---

## ACTIVE: M18 — Store-Aware Shopping (April 1, 2026)

Combined milestone: Store-aware shopping (M18.1) + recipe attribution schema changes (M10.4.0) batched into a single Core Data v11 migration. Store entity, store preferences on templates, store snapshots on grocery items, "Group by Store" view, plus persisting imageURL/author on Recipe.

**PRD**: `docs/prds/active/m18-store-aware-shopping.md`
**Branch**: `feature/M18-store-aware-shopping`
**Estimated**: 7-10 hours (6 sub-milestones)

| Sub | Description | Status |
|-----|-------------|--------|
| M18.1.0 | Schema v11 + model files + HouseholdScoped conformance | COMPLETE |
| M18.1.1 | StoreService (CRUD, assignment, query, cross-store resolve) | COMPLETE |
| M18.1.2 | Store snapshot wiring in GroceryListItemService | COMPLETE |
| M18.1.3 | Store management UI (Settings > Stores) | READY |
| M18.1.4 | Store assignment UX + color dots + "Group by Store" | READY |
| M10.4.0 | Recipe attribution wiring (imageURL + author) | COMPLETE |
| M18.2 | Multi-store + shopping trips (Phase 2, deferred) | PLANNED |

---

## ACTIVE: FUI-1 — Dashboard, Navigation, Recipe UI (April 1, 2026)

Dashboard-first design inspired by Google Stitch mockups + Apple Health card model. Tab restructure (5→4), global search, recipe hero images, grid/list toggle, dashboard with contextual cards.

**PRD**: `docs/prds/active/fui-1-dashboard-navigation-recipe-ui.md`
**Branch**: `feature/M18-store-aware-shopping` (same branch as M18)
**Estimated**: 12-15 hours (7 sub-milestones)

| Sub | Description | Est. | Status |
|-----|-------------|------|--------|
| FUI-1.1 | Tab restructuring (5→4 tabs, add Home) | 1h | READY |
| FUI-1.2 | Search relocation (global search sheet) | 2-3h | READY (depends on FUI-1.1) |
| FUI-1.3 | Settings relocation (gear icon on Dashboard) | 0.5h | READY (depends on FUI-1.1) |
| FUI-1.4 | Recipe detail hero image + source attribution | 1-2h | READY |
| FUI-1.5 | Recipe computed properties for attribution | 0.5h | COMPLETE (~0.5h) |
| FUI-1.6 | Recipe list grid/list toggle with image cards | 2-3h | COMPLETE |
| FUI-1.7 | DashboardView (greeting, cards, quick actions) | 4-5h | READY (depends on FUI-1.1, FUI-1.3) |

---

## COMPLETE: M16.9 — ML Model Retraining (March 28, 2026)

Retrained BiLSTM-CRF v2 with 1,440 harness-labeled entries + strangetom data. Deployed v2 model to app, ported parser fixes + 3 new test classes. PR #105 merged.

**Branch**: `feature/M16.9-ml-model-retraining` (merged)

---

## COMPLETE: M16 — Parsing Test Harness (March 26, 2026)

Standalone CLI tool for automated ingredient parsing evaluation. Fetches 50 recipes from the internet, parses with both local (regex/NLP/hybrid) and Claude API, compares results side-by-side, identifies issues. Designed for ralph loop: run → read report → fix code → retest → commit. Harness uses copied parsing files — app code stays untouched until fixes are validated and ported in a future milestone.

**PRD**: `docs/prds/active/m16-parsing-test-harness.md`
**Branch**: `feature/M16-parsing-test-harness`

Sub-milestones: M16.1-M16.9 ALL COMPLETE

### Results (Newsletter Before → After)

| Metric | Before (Run 1) | After (Run 9) |
|--------|----------------|---------------|
| Avg confidence | 0.93 | **0.97** |
| NLP fallback | 7% | **0.5%** |
| Agreement metric | 37.3% (broken) | **74.8% core** (fixed metric) |
| Parser bugs fixed | 0 | **~20** |
| Training data | 0 | **1,440 entries, 19 sites** |
| Recipes tested | 0 | **~240 across 9 runs** |

Key insight: the initial 37% agreement was a broken thermometer — it conflated design differences with bugs. Two-tier comparison (core vs full match) revealed the real quality was much higher, while making actual bugs clearly visible.

### What's Next
- **M16.9**: ML model retraining using 1,440 labeled entries → the real payoff
- **Port fixes**: Diff harness copies back to app in a future milestone
- **Resume launch path**: M9.28 → M7.7

---

## COMPLETE: M9.35.3 — Leading Comma Display Fix (March 25, 2026)

One-line fix: sanitize rawText in IngredientMatchService.buildResult() so import preview shows "(melted)" instead of "(, melted)". PR #103, build 90.

---

## COMPLETE: M9.35.2 — Parsing Pipeline: Confidence Fix + Float Conversion (March 25, 2026)

Five targeted fixes from phone stress test (27 recipes, build 88): comma-qualifier confidence 0.70→0.92 (~145 prep-in-name fixes), IEEE 754 float→fraction conversion (12+ AllRecipes display bugs), "egg" word-split prevention, can/package size stripping, orphan fragment expansion. Two files changed.
**Actual**: ~1h

---

## COMPLETE: M9.34 — First Import Guide Walkthrough (March 23, 2026)
5-step coach mark overlay on first recipe import. Teaches title editing, ingredient status, split/alternative indicators, AI parse, save. Replayable from Settings.

## COMPLETE: M9.33 — AI Multi-Ingredient Splitting (March 23, 2026)
Auto-splits "X and Y" lines on import preview load. Local heuristic detection + LLM split function. "Each X and Y" pattern distributes quantity. "Or" alternatives flagged with amber banner. Full-width tappable split action row.

## COMPLETE: M9.32 — Grocery Item Name Cleanup (March 23, 2026)
Grocery items show "qty + clean name" instead of raw qualifier text. Template canonical name matching for better aggregation. "1 pound lean ground beef (80/20)" → "1 pound ground beef".

## COMPLETE: M9.31 — CKShare Acceptance Resilience (March 23, 2026)
4-layer ghost detection: owner never ghost-detected, fetchShares retry after 2s, data check (households with recipes/lists never deleted), 3-strike rule across launches.

## COMPLETE: M9.30 — Household Invitation Security (March 22-23, 2026)
Schema v10 (invitedDate, lastInviteDate). 24-hour invite expiration, publicPermission auto-revert, 10-member cap, AES-GCM API key encryption, cancel/revoke invitation UI. Ghost household fix after delete+reinstall.

## COMPLETE: M9.26 — Launch Prep Bug Fixes (March 22-23, 2026)
Meal plan card consistency, editable list/plan names (long-press), Settings tap targets (glass card split), favorites filter pills always visible, recipe source badges toggle, calendar centered, grocery item card styling, quick-add bar, multiline import title, hide Keep Personal option.

## COMPLETE: M9.24 — Member Device Import Store Routing

**Status**: COMPLETE (March 21, 2026, PR #89, build 62)
**Actual**: 0.5h

Scope-aware store assignment in persistAndFinish. Member devices route to shared store, owner devices to private store. Confirmed working via mary.log (target store: shared, parent save=ok, recipe visible to owner).

---

## COMPLETE: M9.15.3 — Returning User Detection After Reinstall

**Status**: COMPLETE (March 21, 2026, build 62)
**Actual**: ~1h (code) + device testing

Household auto-discovers in ~6 seconds after reinstall (attempt 3/30 of polling loop). CKShare membership confirmed, 2 participants restored. Owner device correctly finds Household in private store with valid CKShare. All M9.15 phases now complete (P1: schema v9, P2: create-empty-then-copy, P3: returning user detection).

---

## PLANNED: M9.28 — Remove Diagnostic Logging for Production

**PRD**: `docs/prds/active/m9.28-strip-diagnostic-logging.md`
**Estimated**: 1-2 hours. Gate DiagnosticLogger, DebugLogService, and CloudKitLogger behind `#if DEBUG`. Wrap ~106 caller-site log calls. Remove Settings > Diagnostics section from Release builds. Keep CloudKitLogger's OSLog calls (production-appropriate).

---

## COMPLETE: M9.29 — Refine Claude/AI Logo and Branding

**Status**: COMPLETE (March 21, 2026)
**Actual**: ~0.5h

Removed Claude logo PNGs from asset catalog. Renamed ClaudeParseLabel → AIParseLabel, ClaudeLogo → AISparkleIcon across 13 call sites in 9 files. Replaced with `sparkles` SF Symbol. Updated Settings text to remove "Claude" and "Anthropic" from user-facing strings. Internal ClaudeIngredientParser class name kept (accurately describes API).

---

## RECENTLY COMPLETED

### M9.27: First Launch Walkthrough Redesign — COMPLETE (March 21, 2026)

~4 hours. Replaced 6-step coach mark overlay + sample data with 3-screen welcome carousel. Deleted SampleDataSeeder (~700 lines). Coach marks retained for "Replay Onboarding" in Settings. All fonts/colors use ForagerTheme tokens.
**PRD**: `docs/prds/active/m9.27-first-launch-walkthrough-redesign.md`

### M9.25/M9.25.1: Launch Prep UI Fixes — COMPLETE (March 21, 2026)

~1 hour (PRs #86, #87). Unified visual styling across all views. Converted Settings, Household, HouseholdMembers, ManageCategories, Help from native Form/List to glass card pattern. Centered meal plan day dots and calendar strip. Styled grocery list items as boxed cards.

### M9.23: Member Import Fix — COMPLETE (March 2026)

Fixed member import to refresh ALL updated objects before save. Switched import logging to DiagnosticLogger for Release visibility.

### M9.16: Unified GroceryListItemService — COMPLETE (March 14, 2026)

~4 hours. Consolidated 6 independent GroceryListItem creation paths into single `GroceryListItemService`. Built `MealPlanIngredientSelectionView` wizard for meal plan -> grocery list flow.
**PRD**: `docs/prds/active/m9.16-grocery-list-item-service.md`

---

## COMPLETED MILESTONES (Summary)

| Milestone | Description | Completed |
|-----------|-------------|-----------|
| M9.15 P1-P2 | Household creation rewrite (schema v9, create-share-copy pattern) | March 2026 |
| M9.14 | Household scope bugfixes (ObjectID staleness, HTML decoding) | March 2026 |
| M9.13 | ManagedObjectFactory enforcement (ADR 014) | March 2026 |
| M16.1-16.2 | Knowledge MCP server (Tools/mcp-knowledge/) | March 2026 |
| M10.1-10.3 | Recipe import (URL, text paste, photo/OCR) | Feb-March 2026 |
| M10.5 | Pipeline accuracy + LLM evaluation | March 2026 |
| M10.6 | Claude API integration (M10.6.1-10.6.10, except M10.6.5) | March 2026 |
| M10.8 | Inline ingredient editing | March 2026 |
| M8.4 | ML-powered parsing (BiLSTM-CRF, 10 phases) | February 2026 |
| M8.4.1 | Normalization qualifier reclassification | February 2026 |
| M15 | UX design system + Liquid Glass (7 phases) | February 2026 |
| M7.5 | Architecture hardening (service layer) | February 2026 |
| M9.0/9.1.2/9.5 | Tech debt (warnings, clean names, parser DI) | February 2026 |
| M8.3 | Hybrid NLP parser + template hygiene + auto-merge | February 2026 |
| M8.1 | Parsing resilience + telemetry | February 2026 |
| M7.6 | Pre-launch prep + TestFlight | February 2026 |
| M7.4 | UI polish + pre-launch fixes | February 2026 |
| M7.3.3-7.3.4 | Remove member, delete household, error handling | February 2026 |
| M7.2.2 | Leave household + data migration | January 2026 |
| M7.2.3 | CloudKit hardening (dual-store) | January 2026 |

---

## Known Issues & Limitations

1. **CloudKit**: Members cannot remove themselves from CKShare.participants — workaround: `deleteCKShareFromSharedDatabase()`
2. **Migration**: PlannedMeals not migrated during household leave (require recipe mapping)
3. **CKShare caching**: `getShare(for:)` hits CloudKit on every call; could cache per operation
4. **Household Recovery**: No recovery if owner reinstalls before CloudKit syncs household data

---

## Planning Accuracy

| Milestone | Description | Estimated | Actual | Accuracy |
|-----------|-------------|-----------|--------|----------|
| M1 | Grocery Management | — | 32h | — |
| M2 | Recipe Integration | — | 16.5h | — |
| M3 | Structured Quantity Management | — | 10.5h | — |
| M3.5 | Foundation Validation & Testing | — | 8.5h | — |
| M4.1-4.3.5 | Settings + Meal Planning + Recipe Features | — | 19.25h | — |
| M5.0 | App Renaming & TestFlight | — | 6h | — |
| M7.0-7.1 | App Store + CloudKit Foundation | — | 13.5h | — |
| M7.2.2 | Member Invitation & Leave Flow | — | ~25h | — |
| M7.2.3 | CloudKit Hardening | — | 12.25h | — |
| M7.3-7.4 | Household Mgmt + UI Polish | — | ~10h | — |
| M7.5 | Architecture Hardening | — | ~5h | — |
| M7.6 | Pre-Launch Prep & TestFlight | — | ~12h | — |
| M8.1-8.4 | Parsing Intelligence (4 phases) | — | ~47h | — |
| M9.x | Tech Debt (various) | — | ~14h | — |
| M10.3 | Photo/Image Import | — | ~25h | — |
| M10.5-10.6 | Pipeline Accuracy + Claude API | — | ~26h | — |
| M15 | UX Design System & Visual Refresh | — | ~60h | — |
| M16-16.9 | Parsing Test Harness + ML Retrain | — | ~26h | — |
| M9.24 | Member Import Store Routing | 0.5h | 0.5h | 100% |
| M9.15.3 | Returning User Detection | 1h | ~1h | ~100% |
| M9.30 | Household Invitation Security | 3-5h | ~3h | 100% |
| M9.31 | CKShare Acceptance Resilience | 2-3h | ~1h | 200% |
| M9.32 | Grocery Item Name Cleanup | 1-2h | ~1h | 100% |
| M9.33 | AI Multi-Ingredient Splitting | 3-4h | ~3h | 100% |
| M9.34 | First Import Guide Walkthrough | 2-3h | ~2h | 100% |
| M9.35.2 | Confidence Fix + Float Conversion | — | ~1h | — |
| M9.35.3 | Leading Comma Display Fix | — | <0.5h | — |
| M17.1 | Doc Slimming + PRD Archival | — | ~1h | — |
| M10.4.0 | Recipe Attribution Wiring | 0.75h | ~0.5h | 150% |

| M18.1.0 | Schema v11 + model files | 1.2h | ~1h | ~120% |
| M18.1.1 | StoreService CRUD + tests | 1.1h | ~1h | ~110% |
| M18.1.2 | Store snapshot wiring | 0.6h | ~0.5h | ~120% |
| M10.4.0 | Recipe Attribution Wiring | 0.75h | ~0.5h | 150% |

**Total**: ~320 hours across 40+ milestones | **Remaining to launch**: ~19-24h (M18 remaining + FUI-1 + M9.28 + M7.7)

**Post-launch backlog**: M10.4 (import polish), M6 (testing), M9 remaining, M18.2 (multi-store), FUI-2 (calendar grid), M11+ (~160-200h estimated)

---

## Next Priority

**Phase 1** (parallel): M18.1.3+M18.1.4 (store UI) alongside FUI-1.5→1.4→1.1→1.2→1.3 (recipe UI + tab restructure) and FUI-1.6 (grid toggle).
**Phase 2** (parallel): FUI-1.7 (dashboard) alongside M9.28 (strip logging).
**Phase 3**: PR + merge.
**Phase 4**: M7.7 (App Store submission).

---

**Last Session**: April 1, 2026 — Supervisor orchestration: M18.1.1 StoreService + M18.1.2 snapshot wiring + M10.4.0 attribution (3 parallel workers). PRD audits for M7.7, FUI-1, M9.28. Full launch plan sequencing.
**Next Action**: Phase 1 — spawn workers for M18.1.3+M18.1.4 and FUI-1.5+1.4
**Confidence**: GREEN
