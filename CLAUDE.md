# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Session Startup (MANDATORY)

Run `/forager-session-start` at the beginning of every session. This reads the 4 mandatory context docs, checks git state, and reports current status. No exceptions.

## Build & Run

```bash
open forager.xcodeproj
# Press Cmd+R in Xcode to build and run
# CLI build:
xcodebuild -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

- **Current**: iOS 26+ (Liquid Glass, raised in M15.1)
- Xcode 26.0+, macOS 26.0+
- No external dependencies (pure Swift/iOS frameworks)
- 267 unit tests across 19 test files (M8.4 parsing/ML/telemetry, merge, validation, normalization, integration)
- Debug builds: CloudKit DISABLED (faster local development)
- Release builds: CloudKit ENABLED
- CloudKit container: `iCloud.com.richhayn.forager`

## Naming Convention (Zero Tolerance)

Always use **M#.#.# format** in all code, commits, docs, and branches:

```
M7       = Major Feature (CloudKit Sync & Household Sharing)
M7.2     = Component (Member Invitation & Acceptance)
M7.2.3   = Task (CloudKit Hardening & Shared Data Architecture)
```

Never use "Phase 3", "Step 3", or "Story 7.2.3".

Status indicators: `COMPLETE` | `ACTIVE` | `READY` | `PLANNED`

## Architecture

### CloudKit Dual-Store (M7.2.3)

NSPersistentCloudKitContainer with two persistent stores:

- **Private store** (`forager.sqlite`) - User's personal data, syncs to private CKDatabase
- **Shared store** (`forager_shared.sqlite`) - Household shared data, syncs to shared CKDatabase

Key infrastructure in `Services/Persistence/`:
- `PersistenceController` - NSPersistentCloudKitContainer management
- `DataScope` enum - `.personal` vs `.household(id, store)` scoping
- `HouseholdScopeProvider` - Resolves active household scope
- `ManagedObjectFactory` - Automatic store assignment based on scope
- `CategoryDeduplicator` - Self-healing duplicate prevention (<60s convergence)
- `DefaultSeeder` - One-time default data seeding
- `CloudKitDiagnostics` - Debugging utilities

**Store Assignment Pattern:**
```swift
// Creating household-scoped objects
let factory = ManagedObjectFactory(
    context: context,
    persistence: persistence,
    scopeProvider: scopeProvider
)

let recipe = factory.createRecipe() // Automatically assigned to correct store
```

**Attach-Then-Share Migration Pattern:**
1. Create household record in private store
2. Migrate personal data to household
3. Call `container.share([household], to: nil)` to create CKShare
4. **CRITICAL**: `try viewContext.save()` immediately after sharing
5. Data moves from private to shared zone

**Factory Enforcement (ADR 014):**
- HouseholdScoped entities MUST be created via `ManagedObjectFactory.make()`
- Direct `Entity(context:)` for HouseholdScoped types is FORBIDDEN
- Exceptions: tests, previews, seeders, HouseholdService migration, background contexts with manual householdKey
- HouseholdScoped entities: WeeklyList, Recipe, PlannedMeal, MealPlan, Category, IngredientTemplate, Ingredient, GroceryListItem
- Ingredient and GroceryListItem inherit `household`/`householdKey` from parent (Recipe/WeeklyList) rather than using factory directly (M9.15)
- Non-HouseholdScoped (safe for direct creation): Household, HouseholdMember, UserPreferences

### Service Layer (M7.5+ Standard)

**All Core Data writes MUST go through services.** Views never call `context.save()` directly. See `docs/architecture/service-layer-pattern.md` for the complete standard.

**Service pattern:**
```swift
@MainActor
class ExampleService: ObservableObject {
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let viewContext: NSManagedObjectContext

    // Intent-style methods
    func createExample(name: String) -> Example? {
        do {
            let obj = Example(context: viewContext)
            obj.name = name
            try viewContext.save()
            return obj
        } catch {
            handleError("Failed to create example", error: error)
            return nil
        }
    }
}
```

Key services in `Services/`:
- `HouseholdService` - Household management, CloudKit sharing, member invitations
- `MealPlanService` - Meal planning operations
- `OptimizedRecipeDataService` - Recipe CRUD
- `IngredientParsingService` - Text parsing via 3-tier hybrid parser (<0.05s)
- `IngredientTemplateService` - Normalization & deduplication
- `QuantityMergeService` - Intelligent quantity consolidation
- `UnitConversionService` - Unit conversions (cups/tbsp/tsp, lbs/oz)
- `RecipeScalingService` - Recipe scaling (0.25x-4x)
- `CloudKitSyncMonitor` - Real-time sync tracking

**Always search for existing services before creating new ones.**

### Repository Pattern

Repositories provide **read-only** data access (not writes):
- `CategoryRepository` - Category queries
- `IngredientTemplateRepository` - Template queries
- `PlannedMealRepository` - Meal plan queries

### Ingredient Parsing (M8.4)

3-tier hybrid parser with ML-powered fallback:

```
Input → RegexParser (≥0.9 confidence → return)
      → MLParser    (≥0.8 confidence → return)  [CoreML BiLSTM + Swift Viterbi]
      → NLPParser   (fallback, capped at 0.75)
```

**Key files** in `Services/Parsing/`:
- `IngredientParser.swift` — Protocol (`parse(_ input:) -> ParserResult`)
- `RegexIngredientParser.swift` — Fast deterministic parser (tier 1)
- `MLIngredientParser.swift` — BiLSTM-CRF via CoreML (tier 2)
- `NLPIngredientParser.swift` — NaturalLanguage.framework fallback (tier 3)
- `HybridIngredientParser.swift` — 3-tier router with confidence thresholds
- `ViterbiDecoder.swift` — CRF Viterbi decoding (pure Swift)
- `IngredientTokenizer.swift` — Shared `foragerTokenize()` (frozen contract)

**Architecture rules:**
- `IngredientParsingService` is the public API — callers never use parsers directly
- `foragerTokenize()` is the single tokenizer — used by both inference and correction export
- `MLIngredientParser.init?()` returns nil if model unavailable (graceful degradation)
- Telemetry logs `parserUsed` as winner-only attribution (`"regex"`, `"ml"`, or `"nlp"`)
- Correction feedback: `ParsingTelemetryService.exportCorrectionsAsTrainingData()` → JSONL
- 267 tests across 19 test files cover the full parsing pipeline

### Core Data Model (10 Entities)

- **Grocery**: WeeklyList, GroceryListItem, Category
- **Recipe**: Recipe, Ingredient, IngredientTemplate
- **Meal Planning**: MealPlan, PlannedMeal
- **Household**: Household, HouseholdMember
- **Settings**: UserPreferences

Model has 9 versions (v1-v9, current is v9). Before changing schema, read `docs/architecture/007-core-data-change-process.md` and document impact. CloudKit Production schema is append-only — no destructive changes. v9 added `household`/`householdKey` to Ingredient and GroceryListItem (M9.15).

**Codegen approach:**
- `IngredientTemplate` uses **Class Definition** (auto-generated code)
- `Recipe`/`Ingredient` use **Manual/None** (manual extensions for custom logic)
- New entities: default to Class Definition unless custom extensions needed

**Core Data rules:**
- Always add fetch indexes for frequently queried fields
- Use predicates for database-level filtering (not in-memory)
- **ADR 013**: All service fetches on household-scoped entities MUST include `householdKey` predicate (prevents ghost objects from other stores/households)
- Batch operations for multiple changes
- Background contexts for heavy operations
- CloudKit sync wrapped in `#if !DEBUG`
- Test with sample data before migrating production
- Follow M3 Phase 3 pattern for migrations (successful isStaple migration)

**Data patterns:**
- `IngredientTemplate` is single source of truth (prevents "Butter"/"butter"/"BUTTER" duplication)
- READ-ONLY relationships on templates (no cascade deletes)
- Structured quantities enable scaling and consolidation
- 75+ computed properties for data integrity (M3.5)

### UI Patterns

- SwiftUI with `@FetchRequest` for live Core Data updates
- `NavigationStack` with sheet-based modals
- Native Liquid Glass TabView with 5 tabs: Lists, Recipes, Meals, Settings, Search (ADR 011)
- App entry: `forager/App/foragerApp.swift`, CloudKit share handling: `forager/App/SceneDelegate.swift`
- Views organized by feature: `forager/Views/{Grocery,Recipes,Import,MealPlanning,Household,Settings,Search}/`
- Core Data models: `Models/` (36 entity files, auto-synced)
- All source directories (forager/, Models/, Services/) use `PBXFileSystemSynchronizedRootGroup` — just create files on disk

### Design System (ForagerTheme) — Established M15

**All visual changes must follow the design system.** Before making visual changes, consult:
- `docs/prds/complete/m15-ux-design-system.md` — Color tokens, typography, component specs
- `docs/mockups/forager-design-system.html` — 16 phone-frame HTML mockups (open in browser)

**Design rules:**
- Use `ForagerTheme` semantic color tokens — never hardcode colors
- Typography: SF Pro Rounded for chrome, system default for body text. No serif. See PRD §4.2.1.
- All color pairings must meet WCAG AA (≥ 4.5:1 text, ≥ 3:1 UI elements)
- Empty states: Use native `ContentUnavailableView`
- Check mockups before implementing any screen

## Pre-Development Analysis

Before implementing ANY feature, use these skills as needed:

- `/forager-core-data-audit <EntityName>` — Required before schema changes (ADR 007)
- `/forager-service-check <functionality>` — Required before creating new services
- `/forager-prd-audit <path>` — Required if PRD is >2 weeks old
- `/forager-architecture-audit` — Required before any milestone that creates Core Data objects
- Verify correct M#.#.# format in current-story.md
- Follow established patterns and ADR decisions

## Git Workflow

**One phase = one branch = one PR = one squash commit to main.**

Use these skills for git operations:
- `/forager-new-milestone <M#.#.# description>` — Set up new milestone (branch, docs)
- `/forager-commit` — Commit with M#.#.# conventions (no Co-Authored-By)
- `/forager-pr` — Create PR with project format
- `/forager-build` — Build with correct Xcode configuration

**Key rules** (always in effect):
- Branch naming: `feature/M#.#.#-brief-kebab-case` (3-5 words max)
- Commit prefix: `M#.#.#:` in imperative mood. **No Co-Authored-By credits.**
- Commit every 15-30 min, push after each commit
- Squash merge PRs to main

**GitHub issue integration:**
- Create issue at milestone start: `gh issue create --title "M#.#.#: Title" --label "milestone,feature"`
- Close with completion summary when done

## Documentation Updates (After Every Session)

**7 core docs must stay synchronized.** Use these skills:

- `/forager-log-insight <topic> <insight>` — Log technical insights IMMEDIATELY (don't defer)
- `/forager-dev-journal` — Write/update session narrative (MANDATORY before every commit)
- `/forager-milestone-complete <M#.#.#>` — Update all 7 core docs after milestone completion

**The 7 core documentation files:**
1. `docs/current-story.md` - Current milestone status and progress
2. `docs/next-prompt.md` - Implementation guidance for next milestone
3. `docs/roadmap.md` - Milestone tracking and execution order
4. `docs/requirements.md` - Functional requirements and completion status
5. `docs/project-index.md` - Central navigation hub and metrics
6. `docs/insights-log.md` - Technical insights discovered during session
7. `docs/development-journal.md` - Narrative session entry (decisions, learning, AI tooling)

**Hard rules:**
- Treat every commit as a potential last commit — insights and journal must be current
- After completing ANY milestone, update ALL 7 files automatically (use `/forager-milestone-complete`)
- Do not defer documentation to end-of-session — sessions can be interrupted

## Project Skills (`.claude/skills/`)

Custom skills for forager workflows. Invoke with `/name` or let Claude auto-invoke.

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| `/forager-session-start` | 9-point startup checklist | Every session start |
| `/forager-commit` | Commit with M#.#.# conventions | Every commit |
| `/forager-dev-journal` | Write session narrative entry | Before every commit |
| `/forager-log-insight` | Log technical insight | When discoveries are made |
| `/forager-milestone-complete` | Update all 7 core docs | After milestone completion |
| `/forager-pr` | Create PR with project format | End of each milestone phase |
| `/forager-new-milestone` | Set up new milestone (branch + docs) | Starting new work |
| `/forager-core-data-audit` | Schema impact analysis (ADR 007) | Before schema changes |
| `/forager-service-check` | Duplicate service prevention | Before creating new services |
| `/forager-build` | Build with correct Xcode config | During development |
| `/forager-release-prep` | Full pipeline: branch → PR → merge → archive → TestFlight | Ship a feature to TestFlight |
| `/forager-archive` | Archive, bump build #, upload to TestFlight | Release distribution |
| `/forager-prd-audit` | Verify PRD against current code | Before implementing old PRDs |

## Architecture Decision Records

13 ADRs in `docs/architecture/`:
- **ADR 007**: Core Data change process (read before any schema changes)
- **ADR 008**: Shared zone architecture (dual-store foundation)
- **ADR 009**: Public link sharing (bypasses broken UICloudSharingController on iOS 18.x)
- **ADR 010**: Hybrid parser confidence routing (3-tier: regex → ML → NLP fallback)
- **ADR 011**: Tab architecture reduction (6→5 tabs for M15, read before navigation changes)
- **ADR 012**: GroceryListItem flat string snapshots (snapshot-only, not relationships)
- **ADR 013**: Scope-aware fetch pattern (all service fetches MUST include `householdKey` predicate)
- **Service Layer Pattern**: M7.5+ standard for all Core Data writes

## Code Standards

### Comments and Organization

```swift
// MARK: - Section Name
// MARK: - M7: CloudKit Sync Functions
```

**Comments should explain WHY, not WHAT:**
```swift
// GOOD: Use parsed name to ensure consistency with template matching
listItem.name = parsed.name

// BAD: Set name to parsed name
listItem.name = parsed.name
```

**TODOs must include context:**
```swift
// GOOD:
// TODO (M4): Integrate with meal planning service

// BAD:
// TODO: fix this
```

### Performance Targets

- Queries: <0.1s
- Complex operations: <0.5s
- CloudKit sync: <5s
- Parsing: <0.05s
- UI: 60fps

## Phase-Based Planning

Break work into phases with clear deliverables:

| Phase Type | Duration |
|---|---|
| Core Data model changes | 45-60 min |
| Service layer implementation | 60-90 min |
| Complex features with multiple integration points | 90-120 min |
| UI polish and enhancement | 30-45 min |

**Complexity assessment:**
- **Simple (1-2h)**: UI enhancement, service method additions, basic queries
- **Moderate (3-6h)**: New service creation, multi-view UI, data migrations
- **Complex (8-12h)**: Schema changes + migration + service + UI, new architectural patterns
- **Very Complex (16+h)**: Complete feature with multiple subsystems, major architecture changes

## Quality Gates

**Stop and reassess if:**
- More than 5 consecutive build errors
- Spending >20 min on a single compilation issue
- Breaking existing working features
- Performance degrades below targets
- Creating new services without checking for existing ones
- Working on main branch instead of feature branch
- Creating documentation without updating project-index.md
- Making Core Data changes without impact analysis
- Creating HouseholdScoped entities without ManagedObjectFactory (ADR 014)

**Continue when:**
- Build succeeds first try or with minor fixes (<3 attempts)
- All existing features continue working (no regressions)
- New feature meets performance targets
- Code follows established patterns from M1-M7
- Documentation updated per checklist
- On feature branch with frequent commits

