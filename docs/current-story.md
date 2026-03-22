# Current Development Story

**Last Updated**: March 22, 2026
**Status**: **M9.30 ACTIVE** | **M9.26 ACTIVE** | **M9.29 COMPLETE** | **M10.6.5 COMPLETE**
**Total Progress**: ~290 hours | 89% planning accuracy
**Current Branch**: `feature/M9.30-invite-security-hardening`
**Launch Path**: M9.30 -> M9.26 -> M9.28 -> M7.7

---

## LAUNCH PATH

| Milestone | Description | Est. Hours | Status |
|-----------|-------------|-----------|--------|
| **M9.24** | Member device import -> shared store routing | 0.5h | COMPLETE (PR #89, build 62 confirmed) |
| **M9.15.3** | Returning user detection after reinstall | 1h | COMPLETE (build 62, 6s discovery) |
| **M9.30** | Household invitation security hardening | 3-5h | ACTIVE |
| **M9.26** | Launch prep bug fixes (round 2) | 2-4h | ACTIVE (PR #94, #95 merged) |
| **M10.6.5** | Claude API documentation + verification | 1-2h | COMPLETE |
| **M9.28** | Remove diagnostic logging for production | 1-2h | PLANNED |
| **M9.29** | Refine Claude/AI logo and branding | 1-3h | COMPLETE (~0.5h) |
| **M7.7** | App Store submission | 3-5h | PLANNED |

---

## ACTIVE: M9.30 — Household Invitation Security Hardening

**Status**: ACTIVE (March 22, 2026)
**Estimated**: 3-5 hours (5 phases)
**PRD**: `docs/prds/active/m9.30-household-invitation-security.md`
**Branch**: `feature/M9.30-invite-security-hardening`

Security audit found 2 CRITICAL + 6 HIGH issues. Fixes: 24-hour invite expiration (schema v10), revert publicPermission after acceptance (owner-only), 10-member cap, AES-GCM API key encryption, duplicate invite prevention. CloudKit compatibility validated against Learning Note 44.

---

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

## PLANNED: M9.26 — Launch Prep Bug Fixes (Round 2)

**Estimated**: 2-4 hours. Scope TBD based on testing builds 59-60.

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

**M9.24**: Merge branch + device test member import store routing (0.5h), then **M9.15.3**: Device test returning user detection (1h).

---

**Last Session**: March 21, 2026 — M9.27 COMPLETE, M9.25/25.1 COMPLETE
**Next Action**: Merge M9.24 branch, device test member import + returning user detection
**Confidence**: GREEN
