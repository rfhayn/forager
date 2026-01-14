# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Session Startup (MANDATORY - Read These Every Session)

**Before ANY work, read these 4 documents in order:**

1. `docs/session-startup-checklist.md` - Complete 9-point checklist
2. `docs/project-naming-standards.md` - M#.#.# naming conventions
3. `docs/current-story.md` - Current project status
4. `docs/next-prompt.md` - Implementation guidance (if developing)

**Time Investment**: 10-15 minutes prevents 7-16 hours of rework.

**Full Instructions**: See `docs/claude-instructions.md` for complete development guidelines, architecture patterns, git workflow, and code standards.

---

## Build & Run

```bash
# Open project
open forager.xcodeproj

# Build and run
# Press ⌘+R in Xcode
# Or: Product → Run

# Run on specific simulator
# Select simulator from Xcode toolbar, then ⌘+R

# Debug builds: CloudKit DISABLED (faster local development)
# Release builds: CloudKit ENABLED
```

**No Tests**: Test infrastructure planned for M6 (not yet implemented).

---

## Architecture Overview

### **Core Data Model (10 Entities)**

**Grocery Management:**
- `WeeklyList` - Weekly shopping lists
- `GroceryListItem` - Individual items on lists
- `Category` - Custom store-layout categories

**Recipe System:**
- `Recipe` - Recipe catalog
- `Ingredient` - Recipe ingredients
- `IngredientTemplate` - Normalized ingredient templates (prevents duplication)

**Meal Planning:**
- `MealPlan` - Meal planning periods
- `PlannedMeal` - Recipe assignments to specific dates

**Household & User:**
- `Household` - Household for sharing
- `HouseholdMember` - Members of households
- `UserPreferences` - User settings

### **CloudKit Dual-Store Architecture (M7.2.3)**

**Critical Pattern**: Dual-store NSPersistentCloudKitContainer

```swift
// Private Store (user's personal data)
NSPersistentStore - CKRecordZone: com.apple.coredata.cloudkit.zone

// Shared Store (household shared data)
NSPersistentStore - CKRecordZone: [household-specific shared zone]
```

**Key Components:**
- `DataScope` enum - Defines `.personal` vs `.household(id, store)` scopes
- `HouseholdScopeProvider` - Resolves active household scope
- `ManagedObjectFactory` - Automatic store assignment based on scope
- `CategoryDeduplicator` - Self-healing duplicate prevention (<60s convergence)

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

**Migration Pattern (Attach-Then-Share):**
1. Create household record in private store
2. Migrate personal data to household
3. Call `container.share([household], to: nil)` to create CKShare
4. **CRITICAL**: `try viewContext.save()` immediately after sharing
5. Data moves from private → shared zone

### **Service Layer Pattern (M7.5+ Standard)**

**All Core Data writes MUST go through services.**

See `docs/architecture/service-layer-pattern.md` for complete standard.

**Key Services:**
- `HouseholdService` - Household management & sharing
- `MealPlanService` - Meal planning operations
- `OptimizedRecipeDataService` - Recipe CRUD
- `IngredientParsingService` - Text parsing (<0.05s)
- `IngredientTemplateService` - Normalization & deduplication
- `QuantityMergeService` - Intelligent consolidation
- `UnitConversionService` - Unit conversions
- `RecipeScalingService` - Recipe scaling
- `CloudKitSyncMonitor` - Real-time sync tracking

**Pattern:**
```swift
@MainActor
class ExampleService: ObservableObject {
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let viewContext: NSManagedObjectContext

    // Intent-style methods
    func createExample(name: String) -> Example? {
        // Service owns the save
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

### **Repository Pattern**

**For data access (NOT writes):**
- `CategoryRepository` - Category queries
- `IngredientTemplateRepository` - Template queries
- `PlannedMealRepository` - Meal plan queries

**Repositories provide read-only access. Services handle writes.**

### **Data Patterns**

**Template Normalization:**
- `IngredientTemplate` is single source of truth
- Prevents duplication: "Butter", "butter", "BUTTER" → "butter"
- READ-ONLY relationships (no cascade deletes)

**Structured Quantities:**
- Enables scaling (0.25x - 4x with kitchen-friendly fractions)
- Intelligent consolidation: "1 cup milk" + "2 cups milk" = "3 cups milk"
- Unit conversion: cups ↔ tablespoons ↔ teaspoons

**Performance Targets:**
- Queries: <0.1s
- Complex operations: <0.5s
- CloudKit sync: <5s
- All targets maintained across 119+ hours of development

---

## Critical Architecture Decisions

**ADR 008: Shared Zone Architecture**
- M7 uses CloudKit shared zones (not CKShare participant lists)
- Dual-store architecture (private + shared)
- Household-scoped data automatically assigned to shared store

**ADR 009: Public Link Sharing**
- M7.2.2 uses public link sharing (`publicPermission = .readWrite`)
- Bypasses UICloudSharingController (broken on iOS 18.x)
- ShareSheet for invitation distribution

See `docs/architecture/` for all 9 ADRs + service-layer-pattern.md.

---

## Development Workflow

### **Mandatory Naming Convention**

**Always use M#.#.# format:**
```
✅ CORRECT: "M7.2.3" or "M7.2.3: CloudKit Hardening"
❌ WRONG: "Phase 3", "Step 3", "Story 7.2.3"
```

**Status indicators:**
- ✅ COMPLETE
- 🔄 ACTIVE
- 🚀 READY
- ⏳ PLANNED

### **Git Workflow (Feature Branches)**

```bash
# 1. Create feature branch
git checkout -b feature/M#.#.#-brief-description

# 2. Commit frequently (every 15-30 min)
git add .
git commit -m "M#.#.#: Brief description

- Detailed bullet 1
- Detailed bullet 2"
git push

# 3. When phase complete, create PR
gh pr create --fill

# 4. Squash merge to main
gh pr merge --squash --delete-branch

# 5. Update local
git checkout main
git pull origin main
git branch -d feature/M#.#.#-description
```

**One phase = one branch = one PR = one commit to main**

### **Documentation Updates (After EVERY Session)**

1. Update `docs/current-story.md` with progress
2. Create/update learning notes in `docs/learning-notes/`
3. Mark phases ✅ COMPLETE with actual hours
4. Update `docs/next-prompt.md` for next phase

**Failure to update documentation breaks project continuity.**

---

## Code Standards

### **Comments**

```swift
// MARK: - Section Name

// Function header: Explain WHY and context
// Called when user taps "Add to List"
// Updates consolidationOpportunities count for badge display
private func updateAnalysis() {
    // Inline: Explain non-obvious logic
    // Use parsed name for template matching consistency
    item.name = parsed.name
}
```

### **Core Data Rules**

**Before changing schema:**
1. Read `docs/architecture/007-core-data-change-process.md`
2. Document impact (which entities/relationships affected)
3. Plan migration (lightweight vs custom)
4. Test with sample data
5. Verify build success

**CloudKit Sync:**
- Wrap in `#if !DEBUG` for development speed
- Enable history tracking and remote notifications
- Monitor with `CloudKitSyncMonitor`

### **Performance**

- Add fetch indexes for frequently queried fields
- Use predicates for database-level filtering
- Background contexts for heavy operations
- Batch operations for multiple changes

---

## Project Context

**Planning Accuracy**: 89% average across 119+ hours
**Current Milestone**: M7 - CloudKit Sync & Household Sharing
**Build Success**: 100% (zero breaking changes maintained)
**Technical Debt**: Zero

**Complete journey documented in:**
- `docs/requirements.md` - All functional requirements
- `docs/roadmap.md` - Milestone timeline & tracking
- `docs/learning-notes/` - 27+ implementation notes
- `docs/architecture/` - 9 ADRs + service-layer-pattern
- `docs/prds/` - Product Requirements Documents

---

## Key Principles

1. **Session startup discipline** - Read checklist EVERY session
2. **Naming consistency** - M#.#.# format (zero tolerance)
3. **Search before creating** - Check for existing services/patterns
4. **Document as you go** - Don't defer documentation
5. **Leverage proven patterns** - M1-M7 established patterns
6. **Performance matters** - Maintain <0.5s targets
7. **Zero regressions** - Never break existing features
8. **Feature branch workflow** - One phase = one branch = one PR
9. **Service Layer Standard** - All writes through services (M7.5+)

---

**Last Updated**: January 13, 2026
**For current status**: Read `docs/current-story.md`
**For full instructions**: Read `docs/claude-instructions.md`
