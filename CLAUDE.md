# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Session Startup (MANDATORY)

Before ANY work, read these 4 documents in order:

1. `docs/session-startup-checklist.md` - Complete 9-point checklist
2. `docs/project-naming-standards.md` - M#.#.# naming conventions
3. `docs/current-story.md` - Current project status
4. `docs/next-prompt.md` - Implementation guidance (if developing)

This prevents duplicate services, naming inconsistencies, architecture conflicts, and messy git history.

## Build & Run

```bash
open forager.xcodeproj
# Press Cmd+R in Xcode to build and run
```

- **Current**: iOS 26+ (Liquid Glass, raised in M15.1)
- Xcode 26.0+, macOS 26.0+
- No external dependencies (pure Swift/iOS frameworks)
- 146 unit tests across 7 test files (M8 parsing, telemetry, merge, validation, normalization). Formal test infrastructure planned for M6.
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
- `IngredientParsingService` - Text parsing with regex (<0.05s)
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

### Core Data Model (10 Entities)

- **Grocery**: WeeklyList, GroceryListItem, Category
- **Recipe**: Recipe, Ingredient, IngredientTemplate
- **Meal Planning**: MealPlan, PlannedMeal
- **Household**: Household, HouseholdMember
- **Settings**: UserPreferences

Model has 6 versions (v1-v6, current is v6). Before changing schema, read `docs/architecture/007-core-data-change-process.md` and document impact. CloudKit Production schema is append-only — no destructive changes.

**Codegen approach:**
- `IngredientTemplate` uses **Class Definition** (auto-generated code)
- `Recipe`/`Ingredient` use **Manual/None** (manual extensions for custom logic)
- New entities: default to Class Definition unless custom extensions needed

**Core Data rules:**
- Always add fetch indexes for frequently queried fields
- Use predicates for database-level filtering (not in-memory)
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
- `ForagerTheme` semantic color tokens — never hardcode colors
- `ContentUnavailableView` for all empty states (not custom empty state views)
- App entry: `foragerApp.swift`, CloudKit share handling: `SceneDelegate.swift`

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

Before implementing ANY feature, run these checks:

**1. Naming compliance:**
- Verify correct M#.#.# format in current-story.md
- Confirm status indicators match actual state

**2. Core Data audit (if touching data model):**
```
Search: "Core Data entity [EntityName] properties relationships"
Search: "[EntityName] codegen fetch indexes"
```
Document: existing properties/types, all relationships/inverses, codegen settings, fetch indexes, migration history.

**3. Existing services check (before creating new ones):**
```
Search: "Service [functionality] implementation"
Search: "Parse [data type] service"
```
Can an existing service be extended instead of creating a new one?

**4. Architecture patterns:**
```
Search: "architecture decision [feature area]"
Search: "service-layer-pattern"
```
Follow established patterns and ADR decisions.

**5. PRD freshness check (if PRD exists for the feature):**
- If PRD is >2 weeks old, audit against current codebase before implementation
- Verify entity names match `+CoreDataProperties.swift` files
- Confirm save counts, view structures, and API signatures are current

## Git Workflow

**One phase = one branch = one PR = one squash commit to main.**

```bash
# 1. Start phase
git checkout main && git pull origin main
git checkout -b feature/M#.#.#-brief-description
git push -u origin feature/M#.#.#-brief-description

# 2. During development - commit every 15-30 min
git add <specific-files>
git commit -m "M#.#.#: Brief description

- Detail 1
- Detail 2"
git push

# 3. Complete phase
gh pr create --fill
gh pr merge --squash --delete-branch

# 4. Update local
git checkout main && git pull origin main
git branch -d feature/M#.#.#-description
```

**Branch naming**: `feature/M#.#.#-brief-kebab-case` (3-5 words max)

**Commit message format**: Always prefix with `M#.#.#:` in imperative mood. **Do NOT add Co-Authored-By credits**.

Good commits:
```
M7.1.1: Add CloudKit configuration to Persistence
M7.2.2: Implement public link sharing for household invitations
M7.1.1 COMPLETE: Update documentation and learning notes
```

Bad commits:
```
Fixed stuff
WIP
Update files
Trying to make it work
```

**GitHub issue integration:**
- Create issue at milestone start: `gh issue create --title "M#.#.#: Title" --label "milestone,feature"`
- Close with completion summary when done: `gh issue close <number> --comment "..."`
- Update project board card as status changes

**Emergency scenarios:**

Switch computers mid-phase:
```bash
# Computer A
git add . && git commit -m "M#.#.# WIP: Pausing at X" && git push
# Computer B
git fetch origin && git checkout feature/M#.#.#-description && git pull
```

Accidentally committed to main:
```bash
git branch feature/M#.#.#-description   # Save work to branch
git checkout main && git reset --hard origin/main  # Reset main
git checkout feature/M#.#.#-description  # Continue on branch
```

Abandon branch and start over:
```bash
git checkout main && git branch -D feature/M#.#.#-description
git checkout -b feature/M#.#.#-description-v2
```

## Documentation Updates (After Every Session)

### Core Documentation Definition

**"Core documentation" refers to these 7 files that must stay synchronized:**

1. `docs/current-story.md` - Current milestone status and progress
2. `docs/next-prompt.md` - Implementation guidance for next milestone
3. `docs/roadmap.md` - Milestone tracking and execution order
4. `docs/requirements.md` - Functional requirements and completion status
5. `docs/project-index.md` - Central navigation hub and metrics
6. `docs/insights-log.md` - Technical insights discovered during session
7. `docs/development-journal.md` - Narrative session entry (decisions, learning, AI tooling)

These files form the single source of truth for project status and history. When one changes, the others likely need updates too.

### Session Documentation Updates

1. Update `docs/current-story.md` with progress
2. Create/update learning notes in `docs/learning-notes/`
3. Mark completed phases with actual hours
4. Update `docs/next-prompt.md` for next phase
5. Log any technical insights shared to `docs/insights-log.md` **(MANDATORY — don't defer, sessions can clear)**
6. Write narrative session entry in `docs/development-journal.md` **(MANDATORY — update before each commit, not at end of session)**

### Insights Logging (MANDATORY — During Every Session)

**Whenever you share a technical insight with the user, IMMEDIATELY log it to `docs/insights-log.md`.** Do not defer this to end-of-session — sessions can be interrupted or run out of context. Treat every commit as a potential last commit: insights and journal entries must be current before each commit.

Insights are non-obvious technical observations discovered during implementation — gotchas, platform behaviors, architectural trade-offs, or patterns worth remembering. Each entry must include:

| Column | Description |
|--------|-------------|
| Date | Session date |
| Milestone | Current M#.#.# being worked on |
| Topic | Hierarchical tag (e.g., `iOS/LaunchScreen`, `Swift/Release`, `CoreData/Schema`) |
| Insight | The observation — what was learned |
| Verification | How to test or confirm the insight |
| Status | `Raw` for new entries, `→ ADR ###` or `→ LN ##` when promoted |

**Promotion rules** — periodically review the log:
- **3+ insights on same topic** → Write a Learning Note
- **Architectural decision with trade-offs** → Write an ADR
- **Recurring gotcha** → Add to CLAUDE.md or development-guidelines.md

### Milestone Completion Documentation (MANDATORY)

**After completing ANY milestone (M#.#.#), automatically update ALL 7 core documentation files.**

**Do this automatically without being asked.** The user should not need to request documentation updates after milestone completion.

### Documentation File Structure

```
docs/
├── session-startup-checklist.md    # START HERE every session
├── project-naming-standards.md     # M#.#.# naming conventions
├── current-story.md                # Current milestone status
├── next-prompt.md                  # Implementation guidance
├── development-guidelines.md       # Code standards & patterns
├── git-workflow-for-milestones.md  # Complete git workflow
├── requirements.md                 # Functional requirements
├── roadmap.md                      # Milestone tracking
├── project-index.md                # Central navigation hub
├── insights-log.md                 # Technical insights triage inbox
├── development-journal.md          # Narrative development chronicle
├── prds/                           # Product Requirements Documents
│   ├── active/                     # Current milestone PRDs
│   └── complete/                   # Completed feature PRDs
├── learning-notes/                 # Implementation journey (37 notes)
│   ├── 01-09: M1 phases
│   ├── 10-13: M2 (recipes)
│   ├── 14-15: M3 (quantities)
│   ├── 16-19: M4 (meal planning)
│   ├── 20-21: M5 (app renaming)
│   ├── 22-29: M7 (CloudKit sync)
│   ├── 30-31: M8 (parsing intelligence)
│   └── 32-37: M15 (UX design system)
├── mockups/                        # Visual design references
│   └── forager-design-system.html  # 16 phone-frame mockups (M15)
└── architecture/                   # Architecture Decision Records
    ├── 001-012: ADRs
    └── service-layer-pattern.md    # M7.5+ standard
```

## Architecture Decision Records

12 ADRs in `docs/architecture/`:
- **ADR 007**: Core Data change process (read before any schema changes)
- **ADR 008**: Shared zone architecture (dual-store foundation)
- **ADR 009**: Public link sharing (bypasses broken UICloudSharingController on iOS 18.x)
- **ADR 010**: Hybrid parser confidence routing (regex fast path + NLP fallback)
- **ADR 011**: Tab architecture reduction (6→5 tabs for M15, read before navigation changes)
- **ADR 012**: GroceryListItem flat string snapshots (snapshot-only, not relationships)
- **Service Layer Pattern**: M7.5+ standard for all Core Data writes

## Code Standards

### Comments and Organization

```swift
// MARK: - Section Name
// MARK: - M7: CloudKit Sync Functions

// Function headers: explain WHY and context
// Analyzes the current grocery list for consolidation opportunities
// Updates consolidationOpportunities count which drives badge display
// Called on view appear and whenever list items change
private func updateConsolidationAnalysis() {
    // ...
}

// State management: document purpose and behavior
// M7.1.2: CloudKit sync monitor
// Observes NSPersistentStoreRemoteChange notifications
// Tracks sync state, event count, last sync date
@StateObject private var syncMonitor: CloudKitSyncMonitor
```

**Good comments** explain why and provide context:
```swift
// Use parsed name to ensure consistency with template matching
// This enables fuzzy search to work correctly
listItem.name = parsed.name
```

**Bad comments** restate the code:
```swift
// Set name to parsed name
listItem.name = parsed.name
```

**Actionable TODOs** include context:
```swift
// TODO (M4): Integrate with meal planning service
// TODO (Performance): Consider caching for lists > 100 items
```

**Not this:**
```swift
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

**Continue when:**
- Build succeeds first try or with minor fixes (<3 attempts)
- All existing features continue working (no regressions)
- New feature meets performance targets
- Code follows established patterns from M1-M7
- Documentation updated per checklist
- On feature branch with frequent commits

## Key Principles

1. **Session startup discipline** - Follow checklist EVERY session
2. **Naming consistency** - M#.#.# format everywhere
3. **Search before creating** - Check for existing services/patterns
4. **Document as you go** - Don't defer documentation
5. **Leverage proven patterns** - M1-M7 established excellent patterns
6. **Performance matters** - Maintain targets for all operations
7. **Zero regressions** - Never break existing features
8. **Feature branch workflow** - One phase = one branch = one PR
9. **Service Layer Standard** - All writes through services (M7.5+)
