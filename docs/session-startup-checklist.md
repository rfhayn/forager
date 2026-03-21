# Session Startup Checklist

**Purpose**: Mandatory startup procedure for every Claude development session.

---

## The Checklist

### Phase 1: Context Loading (ALL sessions)

1. **Read this checklist** — `docs/session-startup-checklist.md`
2. **Read naming standards** — `docs/project-naming-standards.md`
   - Verify current active milestone, status indicators
   - Key rule: Always "M7.1.3" not "Phase 3" or "Step 3"
3. **Read current story** — `docs/current-story.md`
   - Current milestone, active/completed/ready work, blockers

### Phase 2: Implementation Preparation (development sessions)

4. **Read next prompt** — `docs/next-prompt.md`
   - Phase breakdown, technical requirements, acceptance criteria
5. **Search Core Data schema** (if working with data model)
   - Verify properties, relationships, codegen settings, fetch indexes
6. **Review relevant ADRs** — `docs/architecture/`
   - Key: ADR 007 (Core Data changes), ADR 008 (shared zone), ADR 013 (scope-aware fetch), ADR 014 (factory enforcement)
   - Service standard: `docs/architecture/service-layer-pattern.md`
7. **Search for existing services** (before creating new ones)
   - Check: OptimizedRecipeDataService, IngredientParsingService, IngredientTemplateService, QuantityMergeService, UnitConversionService, RecipeScalingService, CloudKitSyncMonitor, GroceryListItemService, MealPlanService, HouseholdService
8. **Validate architecture approach** (complex features with multiple options)
   - Document approaches with pros/cons, present recommendation, get confirmation before coding
   - Red flags requiring validation: "multi-user", "collaboration", "sync", "share", "family"
9. **Create feature branch** before writing ANY code
   - Format: `feature/M#.#.#-brief-kebab-case`
   - One phase = one branch = one PR = one squash commit to main

---

## Red Flag Check

Before writing code, verify:
- [ ] No duplicate services being created
- [ ] Using correct M#.#.# naming convention
- [ ] Current work documented in current-story.md
- [ ] Architecture matches established ADRs
- [ ] On feature branch (not main)

Before ending session:
- [ ] Technical insights logged to `docs/insights-log.md`
- [ ] Narrative journal entry written to `docs/development-journal.md`
- [ ] Both files committed and pushed
