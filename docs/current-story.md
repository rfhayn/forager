# Current Development Story

**Last Updated**: March 27, 2026
**Status**: **M16.9 ACTIVE** | **M16 COMPLETE**
**Total Progress**: ~320 hours
**Current Branch**: `feature/M16.9-ml-model-retraining`
**Launch Path**: M18 -> M10.4 -> M9.28 -> M7.7 | **Active**: M16.9 (ML retraining)

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
| **M18** | Store-aware shopping (preferred store, grouped lists) | 12-18h | PLANNED |
| **M10.4** | Recipe attribution, image cache, legal gates | 4-5h | PLANNED |
| **M9.28** | Remove diagnostic logging for production | 1-2h | PLANNED |
| **M7.7** | App Store submission | 3-5h | PLANNED |

---

## ACTIVE: M16.9 — ML Model Retraining (March 27, 2026)

Retrain the BiLSTM-CRF ingredient parsing model using 1,440 AI-labeled training entries collected by the M16 harness. Bridge harness field-level labels (name/qty/unit/notes) to token-level BIO tags, combine with strangetom dataset (55K), rebuild vocabulary, retrain from scratch with oversampling, deploy to app.

**PRD**: `docs/prds/active/m16.9-ml-model-retraining.md`
**Branch**: `feature/M16.9-ml-model-retraining`
**Estimated**: 14-20 hours across 5 sub-milestones

| Sub | Description | Status |
|-----|-------------|--------|
| M16.9.1 | Harness data converter (field→token alignment) | COMPLETE |
| M16.9.2 | Data accumulation + quality review | COMPLETE |
| M16.9.3 | Full retrain (combined dataset + vocab rebuild) | READY |
| M16.9.4 | A/B model comparison + regression check | READY |
| M16.9.5 | Deploy retrained model to app + validate | READY |
| M16.9.6 | Port parser fixes to app + validate | READY |

---

## COMPLETE: M16 — Parsing Test Harness (March 26, 2026)

Standalone CLI tool for automated ingredient parsing evaluation. 9 runs, ~240 recipes, ~20 parser bugs fixed. Produced 1,440 labeled training entries across 19 sites. Core agreement metric: 74.8%.

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

**Estimated**: 1-2 hours. Strip DiagnosticLogger, DebugLogService, and CloudKitLogger output added during M9.15-M9.23 debugging. Determine what to keep behind `#if DEBUG` vs remove entirely.

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

## Next Priority

After M16.9 completes: **M18** Store-Aware Shopping (12-18h, 2 phases). Store entity + preferredStore on IngredientTemplate, grocery list grouped by store with color indicators. PRD: `docs/prds/active/m18-store-aware-shopping.md`. Origin: beta tester feedback (Joe). Requires Core Data schema change. Then M10.4 → M9.28 → M7.7.

---

**Last Session**: March 25, 2026 — M9.35.2 COMPLETE (confidence fix + float conversion)
**Next Action**: M18 (store-aware shopping) → M10.4 → M9.28 → M7.7 (App Store submission)
**Confidence**: GREEN
