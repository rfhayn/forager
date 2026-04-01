# Forager - Project Index

**Last Updated**: April 1, 2026
**Current Milestone**: M18 ACTIVE | FUI-1 ACTIVE
**Launch Path**: M18 (remaining) → FUI-1 → M9.28 → M7.7

---

## Mandatory Session Startup (in order)

1. **[Session Startup Checklist](session-startup-checklist.md)**
2. **[Project Naming Standards](project-naming-standards.md)**
3. **[Current Story](current-story.md)**
4. **[Next Prompt](next-prompt.md)**

---

## Recent Activity

### April 1, 2026 — M18 Build Sprint + FUI-1 Active
- **FUI-1.1**: Tab restructure 5→4 (Home, Lists, Recipes, Meals) + DashboardView placeholder — COMPLETE (5156954)
- **M18.1.4**: Store assignment UX, color dots, "Group by Store" toggle, context menu — COMPLETE (~1h, 9 tests)
- **FUI-1.4**: Recipe detail hero image + source attribution — COMPLETE (e8f983e)
- **M18.1.3**: Store management UI (ManageStoresView, AddStoreView, ForagerTheme+StoreColors) — COMPLETE (e9e5307)
- **FUI-1.6**: Recipe list grid/list toggle with image cards — COMPLETE (bdfedc3)
- **FUI-1.5**: Recipe computed properties for attribution — COMPLETE (861e86a)
- **M18.1.0-M18.1.2**: Schema v11, StoreService, snapshot wiring (3 parallel workers)
- **M10.4.0**: Recipe attribution wiring (imageURL + author) — COMPLETE
- **Pre-launch manual testing doc**: 80+ test cases across all launch path milestones
- **FUI-1**: PRD created for dashboard/navigation/recipe UI (7 sub-milestones, ~12-15h)
- **PRD audits**: M7.7 (updated for iOS 26, ~320h), M9.28 (new PRD), FUI-1 (line refs validated)
- **Launch plan revised**: M18 → FUI-1 → M9.28 → M7.7 (~19-24h remaining)

### March 30, 2026 — FRMWK-2 Lifecycle Automation Adoption
- **FRMWK-2**: Adopted clauductor lifecycle automation framework
  - 7 hooks installed (5 framework + 2 forager-specific: architecture-guard, core-data-guard)
  - 4 new skills (done, pane, start-project, start-work) — 28 total
  - Roadmap.md migrated into current-story.md Planning Accuracy table
  - Terminal auto-launch disabled; `clauductor start` is now the entry point
  - doc-freshness.sh replaces journal-check.sh for pre-commit doc checks

### March 28, 2026 — M16.9 ML Model Retraining COMPLETE
- **M16.9**: Retrained BiLSTM-CRF v2 with harness data (~15h across 2 sessions)
  - v2 model: vocab 5,372→5,454, harness token accuracy +13.45pp, strangetom stable
  - Ported 20+ parser fixes from harness to app (regex, preprocessor, NLP)
  - Fixed test infrastructure (scheme Testables), added 67 new parser tests
  - PR #105, build 91

### March 26, 2026 — M16 Parsing Test Harness + M9.35.3
- **M16**: Standalone CLI tool for automated ingredient parsing evaluation (~5h)
  - 9 harness runs, ~240 recipes tested across 19 sites
  - ~20 parser bugs found and fixed in 3 ralph loop iterations
  - Two-tier comparison logic (37% broken metric → 75% core agreement)
  - 1,440 ML training data entries collected for model retraining
  - PRDs: `docs/prds/active/m16-parsing-test-harness.md`, `docs/prds/active/m16.9-ml-model-retraining.md`
- **M9.35.3**: Leading comma display fix "(, melted)" → "(melted)" (PR #103, build 90)

### March 25, 2026 — M9.35.2 Parsing Pipeline Fixes
- **M9.35.2**: Confidence fix (0.70→0.92), IEEE 754 float→fraction, egg word-split prevention, can/package size stripping, orphan fragment expansion
- 5 targeted fixes in 2 files, ~1 hour

### March 21-23, 2026 — Epic Launch Prep Sprint (29 builds, 16 PRs)
- **M9.30**: Household security hardening (schema v10, 24h invite expiry, AES-GCM encryption, 10-member cap)
- **M9.31**: Ghost detection resilience (4-layer protection against transient CKShare failures)
- **M9.32**: Grocery item name cleanup (clean names for aggregation, template matching)
- **M9.33**: AI multi-ingredient splitting (auto-split "X and Y", alternative indicators)
- **M9.34**: Import guide walkthrough (5-step coach marks on first import)
- **M9.26**: Bug fixes x4 (Settings tap targets, card consistency, favorites, editable names, calendar)
- **M9.29**: Claude/AI branding cleanup (sparkle icons, logo removed)
- **M17.1**: Doc slimming 91% (6,729 → 601 lines) + 17 PRDs archived

### March 21, 2026 - M9.15.3 ✅ COMPLETE — Returning User Detection
- Household auto-discovers in ~6 seconds after delete+reinstall (attempt 3/30)
- CKShare membership validated, 2 participants restored
- All M9.15 phases now complete (schema v9 + create-empty-then-copy + returning user detection)

### March 21, 2026 - M9.27 COMPLETE — First Launch Walkthrough Redesign
- New `WelcomeWalkthroughView` (3-screen carousel), deleted `SampleDataSeeder.swift` (~700 lines)
- Coach marks simplified for replay-only use

### March 21, 2026 - M9.25/M9.25.1 COMPLETE — Launch Prep UI Fixes
- Glass card styling unified, grocery list items styled as boxed cards, meal plan fixes

### March 14, 2026 - M9.16 COMPLETE — Unified GroceryListItemService
- New `GroceryListItemService` consolidating 6 creation paths, `MealPlanIngredientSelectionView`

---

## Documentation Map

**Core Docs** (6 mandatory):
- `docs/current-story.md` — Current milestone status + planning accuracy
- `docs/next-prompt.md` — Implementation guidance
- `docs/requirements.md` — Functional requirements
- `docs/project-index.md` — This file
- `docs/insights-log.md` — Technical insights
- `docs/development-journal.md` — Session narratives

**Architecture**:
- `docs/architecture/` — 13 ADRs (007: Core Data changes, 008: shared zone, 009: public links, 010: parser routing, 011: tab reduction, 012: flat snapshots, 013: scope-aware fetch, 014: factory enforcement)
- `docs/architecture/service-layer-pattern.md` — M7.5+ service standard

**Knowledge**:
- `docs/learning-notes/` — 37 implementation notes
- `docs/prds/` — Product requirement documents
- `docs/MEMORY-SETUP.md` — Claude Code memory system guide

**Skills** (24 total via Clauductor framework):
- Workflow: `/session-start`, `/new-milestone`, `/build`, `/commit`, `/pr`, `/release-prep`
- Documentation: `/dev-journal`, `/log-insight`, `/milestone-complete`
- Pre-development: `/prd-audit`, `/architecture-audit`, `/core-data-audit`, `/service-check`, `/review`
- iOS deployment: `/archive`
- Orchestration: `/claim`, `/release`, `/blocked`, `/status`, `/supervisor`, `/spawn`, `/handoff`, `/assign`
- Meta: `/skills`

**Agents**: `pre-implementation` (service-check + prd-audit + core-data-audit), `session-wrap` (journal + insights + commit)

**Orchestration**: `orchestration/framework.db` — Clauductor multi-worker coordination (workers, locks, events, milestones)

---

## Project Metrics

- **Total Development Time**: ~320 hours
- **Planning Accuracy**: 89%
- **Tests**: 280+ unit tests across 20+ test files
- **Technical Debt**: NONE
- **Stack**: Swift 6+ / SwiftUI / iOS 26+ / Core Data + CloudKit (dual-store)

---

## Milestones

**Complete**: M1 (Grocery), M2 (Recipes), M3 (Quantities), M3.5 (Validation), M4 (Meal Planning), M5.0 (TestFlight), M7.0-M7.6 (CloudKit/Household), M7.5 (Architecture), M8.1-M8.3 (Parsing), M8.4 (ML Parsing), M9.0-M9.5 (Prerequisites), M10.1-M10.9 (Import), M15 (UX Design System), M16.1-M16.2 (MCP)

**Active**: M18 (Store-Aware Shopping — [PRD](prds/active/m18-store-aware-shopping.md), 6/6 subs complete, pending PR)

**Active**: FUI-1 (Dashboard/Navigation/Recipe UI — [PRD](prds/active/fui-1-dashboard-navigation-recipe-ui.md), 4/7 subs complete)

**Queued**: M9.28 (Strip Logging — [PRD](prds/active/m9.28-strip-diagnostic-logging.md)), M7.7 (App Store — [PRD](prds/active/m7.7-app-store-submission.md))

**Recently Completed**: FUI-1.1 (Tab Restructure 5→4), M18.1.4 (Store Assignment UX + Grouping), M18.1.3 (Store Management UI), M18.1.0-M18.1.2 (Schema v11 + StoreService + snapshot wiring), M10.4.0 (Recipe Attribution Wiring)

**Future**: M11 (Analytics), M12 (Health), M13 (Budget), M14 (AI Assistant)

---

**Version**: 10.0
**Repository**: https://github.com/rfhayn/forager.git
