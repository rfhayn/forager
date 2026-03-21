# Forager - Project Index

**Last Updated**: March 21, 2026
**Current Milestone**: M9.15.3 ✅ | M9.24 ✅ | M9.27 ✅ | M17.1 ✅
**Launch Path**: M9.26 → M10.6.5 → M9.28 → M9.29 → M7.7 (~8-15h to App Store)

---

## Mandatory Session Startup (in order)

1. **[Session Startup Checklist](session-startup-checklist.md)**
2. **[Project Naming Standards](project-naming-standards.md)**
3. **[Current Story](current-story.md)**
4. **[Next Prompt](next-prompt.md)**

---

## Recent Activity

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

**Core Docs** (7 mandatory):
- `docs/current-story.md` — Current milestone status
- `docs/next-prompt.md` — Implementation guidance
- `docs/roadmap.md` — Milestone tracking
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

---

## Project Metrics

- **Total Development Time**: ~227 hours
- **Planning Accuracy**: 89%
- **Tests**: 267 unit tests across 19 test files
- **Technical Debt**: NONE
- **Stack**: Swift 6+ / SwiftUI / iOS 26+ / Core Data + CloudKit (dual-store)

---

## Milestones

**Complete**: M1 (Grocery), M2 (Recipes), M3 (Quantities), M3.5 (Validation), M4 (Meal Planning), M5.0 (TestFlight), M7.0-M7.6 (CloudKit/Household), M7.5 (Architecture), M8.1-M8.3 (Parsing), M8.4 (ML Parsing), M9.0-M9.5 (Prerequisites), M10.1-M10.9 (Import), M15 (UX Design System), M16.1-M16.2 (MCP)

**Active**: M9.24 (Launch Prep), M10.6 (Claude API)

**Queued**: M7.7 (App Store), M6 (Testing), M9 (Tech Debt remaining)

**Future**: M11 (Analytics), M12 (Health), M13 (Budget), M14 (AI Assistant)

---

**Version**: 10.0
**Repository**: https://github.com/rfhayn/forager.git
