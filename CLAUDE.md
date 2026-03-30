# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Session Startup (MANDATORY)

Run `/forager-session-start` at the beginning of every session. No exceptions.

## Build & Run

```bash
xcodebuild -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

- iOS 26+, Xcode 26.0+, pure Swift (no external dependencies)
- Debug: CloudKit DISABLED | Release: CloudKit ENABLED
- CloudKit container: `iCloud.com.richhayn.forager`

## Naming Convention (Zero Tolerance)

**M#.#.# format** everywhere — code, commits, docs, branches. Never "Phase 3" or "Step 3".

```
M7 = Major Feature | M7.2 = Component | M7.2.3 = Task
```

Status: `COMPLETE` | `ACTIVE` | `READY` | `PLANNED`

## Architecture (Key Rules)

### CloudKit Dual-Store
- **Private store** (`forager.sqlite`) — personal data + owner's shared zone
- **Shared store** (`forager_shared.sqlite`) — household shared data (member devices)
- **Owner vs member is asymmetric** — never hardcode store assignment, use `HouseholdScopeProvider.activeScope` (ADR 008, M9.24)
- `householdKey` (String) for fetch predicates, `household` (relationship) for zone routing

### Factory Enforcement (ADR 014)
- HouseholdScoped entities MUST use `ManagedObjectFactory.make()`
- Direct `Entity(context:)` is FORBIDDEN (exceptions: tests, previews, seeders, background contexts)
- HouseholdScoped: WeeklyList, Recipe, PlannedMeal, MealPlan, Category, IngredientTemplate, Ingredient, GroceryListItem
- Ingredient/GroceryListItem inherit scope from parent (Recipe/WeeklyList)

### Service Layer (M7.5+)
- **All Core Data writes go through services.** Views never call `context.save()`.
- **All fetches on household-scoped entities MUST include `householdKey` predicate** (ADR 013)
- Always search for existing services before creating new ones

### Core Data Model (11 Entities, v9)
- Schema v9 (current). Read `docs/architecture/007-core-data-change-process.md` before changes
- CloudKit Production schema is append-only — no destructive changes

### UI Patterns
- SwiftUI + `@FetchRequest`, `NavigationStack`, 5-tab Liquid Glass TabView
- **ForagerTheme** semantic color tokens — never hardcode colors
- Typography: SF Pro Rounded for chrome, system default for body. No serif.
- Empty states: `ContentUnavailableView`
- Design system: `docs/prds/complete/m15-ux-design-system.md` + `docs/mockups/forager-design-system.html`

### Ingredient Parsing (M8.4 + M10.6)
- 3-tier local: RegexParser (≥0.9) → MLParser (≥0.8) → NLPParser (fallback, capped 0.75)
- Optional Claude API (M10.6): `ClaudeIngredientParser` fills ~7-8% semantic gap. OFF by default.
- `IngredientParsingService` is the public API — callers never use parsers directly
- LLM methods: `.isLLMAvailable`, `.parseSingleWithLLM()`, `.parseBatchWithLLM()`
- API key stored in Keychain via `LLMSettingsService`, shared across household via CloudKit (M10.6.7)
- Settings > AI Integration: toggle, API key field, test button

## Git Workflow

**One phase = one branch = one PR = one squash commit to main.**

- Branch: `feature/M#.#.#-brief-kebab-case`
- Commit: `M#.#.#:` imperative mood. **No Co-Authored-By.**
- Use skills: `/forager-commit`, `/forager-pr`, `/forager-build`, `/forager-release-prep`

## Documentation (After Every Session)

**7 core docs must stay synchronized.** Use `/forager-milestone-complete` after completions.

1. `docs/current-story.md` — Current status and launch path
2. `docs/next-prompt-M#.#.md` — Per-milestone implementation guidance (branch-specific)
3. `docs/roadmap.md` — Milestone tracking
4. `docs/requirements.md` — Requirements and completion
5. `docs/project-index.md` — Navigation hub
6. `docs/insights-log.md` — Technical insights (log IMMEDIATELY, don't defer)
7. `docs/development-journal.md` — Session narrative (MANDATORY before commits)

## Pre-Development Checks

- `/forager-core-data-audit` — Before schema changes
- `/forager-service-check` — Before creating new services
- `/forager-prd-audit` — If PRD is >2 weeks old
- `/forager-architecture-audit` — Before creating Core Data objects

## Skills

| Skill | When |
|-------|------|
| `/forager-session-start` | Every session start |
| `/forager-commit` | Every commit |
| `/forager-build` | Build the project |
| `/forager-pr` | Create pull request |
| `/forager-release-prep` | Ship to TestFlight |
| `/forager-archive` | Archive + upload |
| `/forager-new-milestone` | Start new work |
| `/forager-milestone-complete` | After completion |
| `/forager-dev-journal` | Before commits |
| `/forager-log-insight` | When discoveries are made |

## ADRs (`docs/architecture/`)

- **007**: Core Data change process | **008**: Dual-store architecture | **009**: Public link sharing
- **010**: Parser confidence routing | **011**: Tab reduction | **012**: GroceryListItem snapshots
- **013**: Scope-aware fetches + store assignment | **014**: Factory enforcement

## Quality Gates

**Stop if:** >5 build errors, >20 min on one issue, breaking existing features, no factory for HouseholdScoped, on main instead of feature branch.


## Clauductor Framework

This project uses [Clauductor](https://github.com/rfhayn/clauductor) for orchestration.

See `template/CLAUDE.md` in the framework repo for the full reference, or run `clauductor update` to sync skills.
