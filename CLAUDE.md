# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🚨 MANDATORY: Session Startup Procedure (READ FIRST)

**CRITICAL**: Before doing ANY work in this repository, you MUST read the following documentation files in order. This is non-negotiable and prevents hours of wasted effort.

### Required Reading (Every Session - No Exceptions)

**Phase 1: Core Context (Required for ALL sessions)**

1. **`docs/session-startup-checklist.md`** ← **START HERE**
   - Complete 8-point startup procedure
   - Ensures naming consistency, documentation continuity, clean git workflow
   - **Estimated time**: 10-15 minutes
   - **Prevents**: 7-16 hours of rework

2. **`docs/project-naming-standards.md`**
   - M#.#.# naming hierarchy (ALWAYS use "M7.2.3" NOT "Phase 3")
   - Status indicators (✅ 🔄 🚀 ⏳)
   - Quick reference card at top

3. **`docs/current-story.md`**
   - Current milestone status
   - Active work (🔄 ACTIVE)
   - Recently completed (✅ COMPLETE)
   - Next planned (🚀 READY)

4. **`docs/next-prompt.md`** (if doing development work)
   - Implementation guide for current session
   - Phase breakdown with time estimates
   - Technical requirements and acceptance criteria

**Phase 2: Strategic Context (Review as needed)**

5. **`docs/claude-instructions.md`**
   - Active work summary
   - Key documentation links
   - Quick reference for current milestone

6. **`docs/development-guidelines.md`**
   - Code documentation standards
   - Quality gates and success indicators
   - Proven patterns from M1-M7
   - Core Data rules and migration patterns

7. **`docs/git-workflow-for-milestones.md`**
   - Feature branch workflow (one phase = one branch = one PR)
   - Commit message format with M#.#.# naming
   - PR creation and squash merge process

8. **`docs/requirements.md`**
   - Functional requirements
   - Feature specifications
   - User needs and goals

9. **`docs/roadmap.md`**
   - Milestone completion tracking
   - Time estimates vs actuals
   - Success metrics (89% planning accuracy)

10. **`docs/project-index.md`**
    - Central navigation hub for all documentation
    - Recent activity and new documentation links
    - Learning notes index

11. **`docs/milestone5.0.1-name-decision-record.md`**
    - App naming history (GroceryRecipeManager → Forager)
    - Brand identity decisions

**Why This Matters:**
- ✅ Prevents duplicate services (check existing before creating new)
- ✅ Maintains naming consistency (M#.#.# format everywhere)
- ✅ Ensures documentation continuity between sessions
- ✅ Follows proven patterns from 119.5+ hours of development
- ✅ Clean git history with feature branch workflow
- ✅ No architectural conflicts or rework

**Time Investment vs Benefit:**
- Reading these docs: ~10-15 minutes
- Rework from skipping: 7-16 hours
- **ROI**: 28-64x return on time invested

---

## Build, Test, and Development Commands

### Building the App
```bash
# Open in Xcode
open forager.xcodeproj

# Build from command line (requires full Xcode installation)
xcodebuild -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 15' build
```

### Running Tests
```bash
# Run all tests
xcodebuild test -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test
xcodebuild test -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:foragerTests/TestClassName/testMethodName
```

### Development Workflow
- **Requirements**: iOS 18.5+, Xcode 15.0+, macOS Sonoma 14.0+
- **Target Platform**: iOS physical devices and simulators
- **Build Configuration**:
  - Debug builds use local Core Data only (fast iteration)
  - Release builds enable CloudKit sync (`#if !DEBUG` wrapper)

## High-Level Architecture

### Core Data + CloudKit Dual-Store Architecture

Forager uses a sophisticated **shared zone architecture** for household collaboration:

**Key Architectural Decisions:**
- **NSPersistentCloudKitContainer** with CloudKit shared zones for multi-user collaboration
- **Dual-store design**: Private store (user-scoped) + Shared store (household-scoped)
- **Scope-based factory pattern** automatically assigns entities to correct store
- **DataScope enum**: `.user` (private data) vs `.household` (shared data)
- **HouseholdScopeProvider**: Runtime determination of which store to use

**Why Shared Zones vs CKShare:**
- Users want ONE shared household database (not selective item sharing)
- All recipes, lists, meal plans, categories automatically sync between household members
- Simpler UX: one-time household setup, no per-item share buttons
- Better for target use case: couples/roommates managing shared household

**Critical Implementation Details:**
```swift
// All household-scoped entities implement HouseholdScoped protocol
protocol HouseholdScoped: NSManagedObject {
    var householdKey: String? { get set }
}

// Factory pattern assigns entities to correct store at creation time
let recipe = factory.create(Recipe.self, scope: .household)  // → Shared store
let userPref = factory.create(UserPreferences.self, scope: .user)  // → Private store
```

See `docs/architecture/008-shared-zone-architecture.md` for complete architectural rationale.

### Core Data Model (9 Entities)

**Current Schema Version**: `forager 2` (located in `forager/forager.xcdatamodeld/`)

**Household-Scoped Entities** (shared between household members):
- `Recipe` - Recipe catalog with ingredients, instructions, usage tracking
- `Ingredient` - Recipe ingredients with structured quantities
- `IngredientTemplate` - Normalized ingredient names (deduplication singleton pattern)
- `Category` - Custom categories for store-layout optimization
- `WeeklyList` - Grocery lists with source recipe tracking
- `GroceryListItem` - Individual list items with quantities and categories
- `MealPlan` - Calendar-based meal planning
- `PlannedMeal` - Individual meals assigned to dates

**User-Scoped Entities** (private to each user):
- `UserPreferences` - User settings (meal plan duration, start day, etc.)

**Key Relationships:**
- `Household` → all household-scoped entities (one-to-many)
- `Recipe` ↔ `Ingredient` (one-to-many with cascade delete)
- `Ingredient` → `IngredientTemplate` (many-to-one, READ-ONLY, no cascade)
- `GroceryListItem` ↔ `Recipe` (many-to-many for source tracking)
- `Category` custom sort order managed via `sortOrder` integer property

**Template System**: IngredientTemplate acts as a single source of truth for ingredient names. Multiple recipes reference the same template, preventing duplication ("Butter", "butter", "BUTTER" all normalize to "butter" template).

### Service Layer Architecture

Located in `/Services/` directory. All services follow singleton pattern with `@Published` properties for SwiftUI observation.

**Core Services:**
- `OptimizedRecipeDataService` - Recipe CRUD operations with performance optimization
- `IngredientParsingService` - Text parsing for ingredient entry (regex-based, <0.05s)
- `IngredientTemplateService` - Template normalization and deduplication
- `IngredientAutocompleteService` - Fuzzy matching for ingredient entry (parse-then-autocomplete)
- `QuantityMergeService` - Intelligent consolidation of duplicate list items
- `UnitConversionService` - Measurement conversion (cups ↔ tbsp ↔ tsp, lbs ↔ oz)
- `RecipeScalingService` - Recipe quantity scaling with kitchen-friendly fractions
- `MealPlanService` - Meal planning with calendar integration
- `UserPreferencesService` - User settings management
- `HouseholdService` - Household creation, sharing, member management
- `CloudKitSyncMonitor` - Real-time CloudKit sync status monitoring

**Persistence Services** (`/Services/Persistence/`):
- `PersistenceController` - Core Data stack initialization and configuration
- `DefaultSeeder` - Initial data seeding for new installations
- `ManagedObjectFactory` - Scope-based entity creation (private vs shared store)
- `HouseholdScopeProvider` - Runtime store selection based on household membership
- `CategoryDeduplicator` - Self-healing category deduplication (<60s convergence)
- `CloudKitDiagnostics` - DEBUG-only CloudKit logging and diagnostics
- `StoreIdentityLogger` - DEBUG-only store identity verification

**Repository Pattern** (`/forager/Repositories/`):
- `CategoryRepository` - Household-aware category CRUD
- `IngredientTemplateRepository` - Household-aware template management
- `PlannedMealRepository` - Household-aware meal plan queries

### UI Architecture

**SwiftUI Patterns:**
- `@FetchRequest` with predicates for live Core Data updates
- `@StateObject` for service initialization
- `@EnvironmentObject` for dependency injection (ManagedObjectFactory, HouseholdScopeProvider)
- Navigation with sheets and `NavigationStack`
- Form validation with unsaved changes detection

**Key Views:**
- `WeeklyListsView` - Grocery list management with consolidation preview
- `RecipeListView` - Recipe catalog with search and usage tracking
- `MealPlanListView` - Calendar-based meal planning
- `SettingsView` - User preferences and household management

**Design Patterns:**
- Category-aware organization throughout app (custom sort order respected)
- Real-time search with native iOS patterns
- Progress overlays for long-running operations
- Visual feedback (checkmarks, strikethrough, scale indicators)

### Performance Standards

All operations must meet these validated targets:
- Query performance: **< 0.1s**
- Search performance: **< 0.2s**
- Autocomplete: **< 0.1s**
- Parsing: **< 0.05s**
- Recipe scaling: **< 0.5s**
- Consolidation analysis: **< 0.5s**
- CloudKit sync: **< 5s** for typical operations
- UI responsiveness: **60fps** maintained

Performance monitoring built into services via `@Published` properties.

## Project-Specific Guidelines

### Milestone Naming Convention (CRITICAL)

**Always use M#.#.# format** for all milestone references:

```
✅ CORRECT: "M7.2.3" or "M7.2.3: CloudKit Hardening"
❌ WRONG: "Phase 3", "Step 3", "Story 7.2.3"
```

**Status Indicators:**
- ✅ **COMPLETE** - Fully implemented and validated
- 🔄 **ACTIVE** - Currently being worked on
- 🚀 **READY** - Next in queue, ready to start
- ⏳ **PLANNED** - Future work, not ready yet

See `docs/project-naming-standards.md` for complete naming hierarchy and enforcement rules.

### Git Workflow (Feature Branch Model)

**One phase = one branch = one PR = one squash commit to main**

```bash
# Phase start
git checkout main
git pull origin main
git checkout -b feature/M7.2.3-cloudkit-hardening

# Development (commit frequently every 15-30 min)
git add <files>
git commit -m "M7.2.3: Brief description
- Detail 1
- Detail 2"
git push

# Phase complete
gh pr create --fill
gh pr merge --squash --delete-branch
git checkout main && git pull origin main
```

**Benefits**: Clean main history (one commit per phase), easy rollback, safe experimentation.

See `docs/git-workflow-for-milestones.md` for complete workflow.

### Core Data Changes (MANDATORY PROCESS)

**Before modifying Core Data schema:**

1. Search project knowledge for `ADR 007 core-data-change-process`
2. Document impact in `M#.#.#-CORE-DATA-IMPACT-ANALYSIS.md`
3. Verify codegen settings: IngredientTemplate uses "Class Definition", most others use "Manual/None"
4. Add fetch indexes for frequently queried fields
5. Test migration with sample data
6. Verify build success and no data loss

**Proven migration pattern**: See M3 Phase 3 for successful `isStaple` migration example.

### Service Creation Guidelines

**Before creating a new service:**

1. Search for existing services that can be extended
2. Review proven patterns from M1-M7 (see `docs/learning-notes/`)
3. Follow singleton pattern with `@Published` properties
4. Include performance monitoring
5. Document with function header comments explaining "why" not "what"

**Reuse over reinvention**: M1-M7 established excellent patterns - always leverage them.

### Code Documentation Standards

**Required for all new code:**

```swift
// MARK: - Section Organization
// Use MARK comments to organize code into logical sections

// Function Header Comments (required)
// Explains what the function does, side effects, special conditions
private func updateConsolidationAnalysis() {
    // Implementation
}

// State Management Comments (required)
// M7.2.3: CloudKit sync monitor
// Observes NSPersistentStoreRemoteChange notifications
@StateObject private var syncMonitor: CloudKitSyncMonitor
```

**Comment principle**: Explain "why" not "what". Code should be self-documenting through clear naming.

### Documentation Requirements

**After every development session:**
- Update `docs/current-story.md` with progress (use correct M#.#.# naming)
- Create/update learning notes in `docs/learning-notes/`

**After every phase completion:**
- Mark phase ✅ COMPLETE in `docs/current-story.md` with actual hours
- Update `docs/next-prompt.md` for next phase
- Update `docs/project-index.md` Recent Activity

**After every milestone completion:**
- Update `docs/roadmap.md` with completion summary
- Update `docs/project-index.md` with milestone links

### Quality Gates

**Stop immediately if:**
- More than 5 build errors consecutively
- Spending > 20 minutes on single compilation issue
- Breaking existing working features
- Performance degrades below targets (>0.5s for operations, >5s for CloudKit)
- Using incorrect M#.#.# naming
- Making Core Data changes without impact analysis
- Creating new services without checking for existing ones
- Working on main branch instead of feature branch

### Key Architectural Patterns to Maintain

**Template Normalization:**
- IngredientTemplate is single source of truth for ingredient names
- Templates are READ-ONLY from ingredient perspective (no cascade deletes)
- Use `IngredientTemplateService` for all template operations

**Scope-Based Store Assignment:**
- Use `ManagedObjectFactory.create(_:scope:)` for entity creation
- Never directly instantiate entities with `NSEntityDescription`
- Factory pattern ensures entities land in correct store (private vs shared)

**Background Operations:**
- Heavy operations must use background contexts
- UI-blocking operations are unacceptable
- Use progress overlays for operations >0.5s

**CloudKit Sync:**
- Wrapped in `#if !DEBUG` for development speed
- Monitor sync with `CloudKitSyncMonitor`
- Handle offline gracefully (queued operations)
- Use `CategoryDeduplicator` pattern for self-healing multi-device sync

## Development Context

**Project Status**: 119.5+ hours of development across M1-M7.2.3 with 89% planning accuracy

**Current Focus**: M7.2.2 member invitation testing (after completing M7.2.3 CloudKit hardening)

**Success Metrics**:
- 89% planning accuracy (<11% variance)
- 100% build success rate (zero breaking changes)
- 100% performance targets met or exceeded
- Clean main branch history via feature branch workflow

**Target Users**: Couples and roommates managing shared household grocery shopping and meal planning

**Quality Philosophy**: Build incrementally, validate continuously, leverage proven patterns, document everything
