# Development Guidelines for Forager iOS

**Project**: Forager — Household Grocery & Recipe Management
**Last Updated**: March 29, 2026
**Version**: 4.0 — Comprehensive Architecture & Production Guidance
**GitHub Repository**: https://github.com/rfhayn/forager.git

---

## CRITICAL: MANDATORY STARTUP PROCEDURE

**Every development session begins with these actions in order:**

1. **Run `/session-start`** — Git status, current branch, milestone context, and dependency check
2. **Read [CLAUDE.md](/CLAUDE.md)** — Authoritative guidance on architecture, naming conventions, and session workflow
3. **Read [current-story.md](current-story.md)** — Active milestone, launch path, and recent progress
4. **Read branch-specific next-prompt** — Implementation plan for your current work session

**Skipping this sequence breaks project continuity.** Failing to read CLAUDE.md causes architectural violations, naming inconsistencies, duplicate services, and silent data bugs.

---

## PROJECT OVERVIEW

**Forager** is an iOS 26+ application for household grocery and recipe management, built with Swift 6, SwiftUI, and Core Data + CloudKit.

- **~320 hours of development** across **40+ milestones**
- **11 Core Data entities** (v10 current, v11 planned for M18)
- **64 services** spanning parsing, import, persistence, and household management
- **267 unit tests** across 19 test files
- **Zero external dependencies** — pure Swift + iOS frameworks
- **Production-ready** — TestFlight build 91, 4 major launches

---

## ARCHITECTURE ESSENTIALS

### Dual-Store CloudKit (ADR 008)

- **Private Store** (`forager.sqlite`) — personal data + owner's shared zone
- **Shared Store** (`forager_shared.sqlite`) — household collaborative data
- **Key Rule**: Never hardcode store assignment. Use `HouseholdScopeProvider.activeScope` (M9.24)

### Household Scoping (ADR 013 + ADR 014)

**Scope-Aware Entities** (all require `householdKey` predicate on fetches):
Recipe, WeeklyList, MealPlan, PlannedMeal, Category, IngredientTemplate, Ingredient, GroceryListItem, Store (M18)

**Creation Rule** (ADR 014 — Zero Tolerance):
- ALL HouseholdScoped entities MUST use `ManagedObjectFactory.make(householdKey:)`
- Direct `Entity(context:)` is **FORBIDDEN** (exceptions: tests, previews, seeders, background contexts)

**Fetch Rule** (ADR 013):
```swift
// WRONG — returns objects from all stores including ghosts
let request = Recipe.fetchRequest()

// CORRECT — scope to current household
let request = Recipe.fetchRequest()
request.predicate = NSPredicate(format: "householdKey == %@", householdKey)
```

### Service Layer (M7.5+)

All Core Data writes go through services. Views NEVER call `context.save()`.

Before creating new services, run `/service-check` to search for existing infrastructure.

### Core Data Model (v10, 11 Entities)

Household, HouseholdMember, Recipe, Ingredient, WeeklyList, GroceryListItem, MealPlan, PlannedMeal, Category, IngredientTemplate, UserPreferences, Store (M18)

**Critical**: CloudKit Production schema is **append-only**. Never delete properties, rename, or change types.

---

## INGREDIENT PARSING PIPELINE (M8.4 + M10.6)

### 3-Tier Local Parsing

- **Regex** (Tier 1): 8 patterns, confidence 0.70-1.0, <0.1ms
- **ML** (Tier 2): BiLSTM-CRF v2, 5,454 vocab, confidence 0.75-0.99, ~100ms
- **NLP** (Tier 3): Natural Language framework, capped at 0.75

### Confidence Routing (ADR 010)
- Regex >= 0.92: accept directly
- Regex 0.70-0.91: compare to ML, take higher
- ML >= 0.75: accept ML
- Otherwise: NLP fallback + human review flag

### Optional Claude API (M10.6)
- Fills ~7-8% semantic gap, OFF by default
- API key stored in Keychain, synced via CloudKit (M10.6.7)

---

## UI PATTERNS & DESIGN SYSTEM (M15)

- **iOS 26+**, SwiftUI + @FetchRequest, NavigationStack
- **Liquid Glass** design with 5-tab TabView
- **ForagerTheme** semantic color tokens — never hardcode colors
- **Typography**: SF Pro Rounded for chrome, system default for body. No serif.
- **Empty States**: ContentUnavailableView with action buttons
- **Design system reference**: `docs/prds/complete/m15-ux-design-system.md`

---

## GIT WORKFLOW

**One phase = one branch = one PR = one squash commit to main.**

- **Branch**: `feature/PREFIX-#.#-brief-kebab-case`
- **Commit**: `PREFIX-#.#: imperative description` — No Co-Authored-By
- **PR**: Structured body (Summary, Changes, Testing, Time, Next)
- **Merge**: Squash to main

---

## DOCUMENTATION STANDARDS (7 Core Docs)

These files must stay synchronized. Use `/milestone-complete` after completions.

1. **current-story.md** — Current milestone status, launch path, and planning accuracy
2. **next-prompt-[milestone].md** — Branch-specific implementation guidance
3. **requirements.md** — Requirements and completion status
4. **project-index.md** — Navigation hub for all documentation
5. **insights-log.md** — Technical insights (log IMMEDIATELY, never defer)
6. **development-journal.md** — Session narrative (MANDATORY before commits)

---

## ARCHITECTURE DECISION RECORDS

| # | Title | Context |
|---|-------|---------|
| 007 | Core Data Change Process | Schema migration methodology |
| 008 | Shared Zone Architecture | CloudKit household sharing |
| 009 | Public Link Sharing | iOS 18 invitation workaround |
| 010 | Hybrid Parser Confidence Routing | Parsing strategy |
| 011 | Tab Architecture Reduction | UX simplification |
| 012 | Grocery Item Snapshot Architecture | Store-at-add-time |
| 013 | Scope-Aware Fetch Pattern | Ghost object prevention |
| 014 | ManagedObjectFactory Enforcement | Cross-store safety |

---

## QUALITY GATES

**Stop and reassess if:**
- More than 5 build errors consecutively
- Spending >20 minutes on a single compilation issue
- Breaking existing working features
- Skipping HouseholdScoped factory enforcement (ADR 014)
- Creating new service without `/service-check`
- Making Core Data changes without `/core-data-audit`
- Committing without development journal entry
- On main branch instead of feature branch

---

## PRE-DEVELOPMENT CHECKS

```
/session-start              # Every session
/service-check              # Before creating services
/core-data-audit            # Before schema changes
/architecture-audit         # Before creating Core Data objects
/prd-audit                  # If PRD is >2 weeks old
```

---

## CURRENT STATE (March 2026)

**Launch Path**: M18 → M9.28 → M7.7 (~11-18 hours remaining)

- **M18**: Store-Aware Shopping + Recipe Attribution (ACTIVE)
- **64 services**, **267 unit tests**, **13 ADRs**
- **Build 91** on TestFlight

---

## KNOWN ISSUES

1. **Cross-Store Relationships** — Private-store objects cannot reference shared-store Household. Use `householdKey` (String) for scoping.
2. **Ghost Households** — Failed CloudKit sync can leave orphaned objects. `cleanOrphanedHouseholdData()` before operations.
3. **Share Corruption** — Public link acceptance can corrupt CKShare. M9.30 added 4-layer resilience.
4. **ML Probabilistic Behavior** — BiLSTM-CRF produces slight variation on rare sequences. Use `contains` not `assertEqual` for ML test assertions.
5. **Unicode Fractions** — Recipe sites store fractions as IEEE 754 floats. Detection via 8+ decimal digits.

---

## RESOURCES

- `CLAUDE.md` — Authoritative guidance (source of truth)
- `docs/architecture/` — 13 ADRs
- `docs/learning-notes/` — 37 implementation journals
- `docs/prds/` — Product requirements for 40+ milestones
- `docs/mockups/forager-design-system.html` — UI mockups (M15)

---
