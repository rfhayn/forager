# Next Implementation Prompt

**Last Updated**: February 11, 2026
**For Milestone**: M7.6 — Pre-Launch Prep & TestFlight Submission
**Status**: IN PROGRESS (M7.6.1 ✅ COMPLETE)
**Branch**: `feature/M7.6-pre-launch-testflight`

---

## **M7.6: PRE-LAUNCH PREP & TESTFLIGHT**

### **Context**
- M8 complete and merged to main (PR #30)
- M7.6.1 App Configuration complete (deployment target, launch screen with light/dark)
- On branch `feature/M7.6-pre-launch-testflight`

### **Phase Execution Order**

M7.6 has 8 phases. Phases 1-6 can be done in any order. All must complete before phase 7 (submission).

**Completed:**
1. ✅ **M7.6.1** (30 min) — Display name, iOS 18.0 target, branded launch screen

**Next quick win:**
2. **M7.6.2** (30 min) — Wrap developer tools in `#if DEBUG`

**Then the bigger pieces:**
3. **M7.6.4** (1-1.5h) — Schema P0: Remove Tag, LeaveRequest, fix plannedMeals
4. **M7.6.5** (1-1.5h) — Schema P1: Rename ownerEmail, fix delete rules, code mismatches
5. **M7.6.6** (1-1.5h) — Schema P2: Remove unused fields, fix sourceURL tags hack
6. **M7.6.3** (3-4h) — Onboarding walkthrough (largest piece, do last before submission)

**Then submit:**
7. **M7.6.7** (1.5h) — Deploy CloudKit schema to Production, archive, submit to TestFlight
8. **M7.6.8** (15 min) — Generate public link after Apple approval (24-48h wait)

### **Key Technical Details**

**Schema Cleanup (M7.6.4-M7.6.6)**:
- Create Core Data model v3 (current is v2)
- CloudKit Production schema is **append-only** once deployed — changes are permanent
- Lightweight migration should handle all changes
- Test migration with existing v2 data before submitting

**P0 Changes (M7.6.4):**
- Delete `Tag` entity (unused, never implemented)
- Delete `LeaveRequest` entity (deprecated, replaced by KeychainHelper)
- Change `Recipe.plannedMeals` from toOne (maxCount=1) to toMany

**P1 Changes (M7.6.5):**
- Remove `Recipe.titleKey` attribute + `byTitleKey` fetch index (dead)
- Add `Household.ownerRecordName`, migrate from `ownerEmail`, remove old field
- Change `Household.mealPlans` delete rule from Nullify to Cascade
- Add `PlannedMeal.household` relationship + `householdKey` attribute to schema
- Add `Household.plannedMeals` inverse relationship to schema

**P2 Changes (M7.6.6):**
- Remove `GroceryItem.ingredientTemplate` and `stapleItems` (unused relationships)
- Remove `GroceryListItem.isFromRecipe` (write-only, replaced by contributingRecipes)
- Add `Recipe.tags` attribute, migrate from `sourceURL` prefix hack
- Standardize `dateCreated`/`createdDate` naming
- Fix `byisActiveandstateDate` index typo

**Onboarding (M7.6.3):**
- 4-page horizontal walkthrough using `TabView` + `.tabViewStyle(.page)`
- `@AppStorage("hasCompletedOnboarding")` for first-launch detection
- Present as `.fullScreenCover` from app root
- "Replay Onboarding" row in Settings

**Production Gating (M7.6.2):**
- Wrap `developerToolsSection` in `#if DEBUG` in SettingsView.swift
- Gate "Create Test Recipes" in RecipeListView.swift

### **Key Files for Context**

```
forager/SettingsView.swift                    # M7.6.2: Developer tools gating
forager/forager.xcdatamodeld/                 # M7.6.4-6: Schema changes (v2 → v3)
forager/foragerApp.swift                      # M7.6.3: Onboarding presentation
forager/CustomBottomNavigation.swift          # M7.6.3: Alternative onboarding host
Services/HouseholdService.swift               # M7.6.5: ownerEmail → ownerRecordName
Household+CoreDataProperties.swift            # M7.6.5: Schema alignment
PlannedMeal+CoreDataProperties.swift          # M7.6.5: Schema alignment
docs/prds/active/m7.6-pre-launch-testflight.md  # Full PRD with all details
docs/prds/active/m7.7-app-store-submission.md    # M7.7 PRD for after TestFlight
```

### **Verification**

After each schema phase, verify:
```bash
xcodebuild -project forager.xcodeproj -scheme forager \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

After all phases, run tests:
```bash
xcodebuild test -project forager.xcodeproj -scheme forager \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:foragerTests
```

---

**Version**: February 11, 2026 - M7.6.1 Complete, M7.6.2 Next
**Dependencies**: M8 complete and merged to main ✅
