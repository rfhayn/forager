# Next Implementation Prompt

**Last Updated**: January 2, 2026  
**For Milestone**: M7.2.3 - CloudKit Hardening & Shared Data Architecture  
**Status**: 🚀 **PHASE 0 READY - Prep Phase Complete**  
**Estimated Duration**: 3-4 hours (Phase 0)

---

## ✅ **PREP PHASE COMPLETE** (1 hour - Jan 2, 2026)

**Completed**:
- ✅ StoreIdentityLogger.swift - DEBUG utility for store identification
- ✅ MigrationValidationTests.swift - Core Data migration safety net

**Result**: Infrastructure ready for Phase 0 model changes

---

## 🚀 **PHASE 0: CORE DATA MODEL CHANGES - START HERE NEXT SESSION**

**Current State:**
- ✅ PRD v2.2 FINAL ready (1597 lines, externally validated)
- ✅ Prep Phase complete (migration validation + store logging)
- ✅ Phase 1 complete (Persistence decomposition, 5h)
- ✅ Phase 3.8 complete (CategoryDeduplicator, 1h)

**What's Next**: Phase 0 - Core Data Model Changes (3-4 hours)  
**Purpose**: Add household relationships to enable shared data architecture

---

## 📋 **PHASE 0 IMPLEMENTATION GUIDE**

### **Overview**

Add `household` relationship to 4 entities + `householdKey` semantic string attributes. This creates Core Data model version 2 and enables the shared data architecture.

**PRD Reference**: Lines 325-423 in `docs/prds/m7.2.3-cloudkit-hardening-household-repositories.md`

---

### **Phase 0.1: Create Model Version 2** (30 minutes)

**Goal**: Create new Core Data model version with household relationships

**Steps**:
1. In Xcode, open `forager.xcdatamodeld`
2. Editor → Add Model Version → Name it "forager 2"
3. Select new version in File Inspector
4. Set "forager 2" as current model version

**Verification**:
```bash
# Should show forager 2.xcdatamodel as current
ls -la forager.xcdatamodeld/
```

---

### **Phase 0.2: Add Household Relationship to Recipe** (30 minutes)

**Entity**: Recipe

**Add Relationship**:
- Name: `household`
- Destination: `Household`
- Type: To One
- Optional: **YES** (critical for migration!)
- Delete Rule: Nullify
- Inverse: `recipes` (on Household)

**Add Attribute**:
- Name: `householdKey`
- Type: String
- Optional: YES
- Indexed: YES
- Used By: CloudKit

**Why householdKey**: 
- Semantic duplicate detection requires comparing strings, not relationships
- CloudKit predicate queries need string attributes
- Enables efficient lookups without fetching full object graph

---

### **Phase 0.3: Add Household Relationship to IngredientTemplate** (30 minutes)

**Entity**: IngredientTemplate

**Add Relationship**:
- Name: `household`
- Destination: `Household`
- Type: To One
- Optional: **YES**
- Delete Rule: Nullify
- Inverse: `ingredientTemplates` (on Household)

**Add Attribute**:
- Name: `householdKey`
- Type: String
- Optional: YES
- Indexed: YES
- Used By: CloudKit

**Critical**: IngredientTemplate deduplication relies on householdKey matching

---

### **Phase 0.4: Add Household Relationship to Category** (30 minutes)

**Entity**: Category

**Add Relationship**:
- Name: `household`
- Destination: `Household`
- Type: To One
- Optional: **YES**
- Delete Rule: Nullify
- Inverse: `categories` (on Household)

**Add Attribute**:
- Name: `householdKey`
- Type: String
- Optional: YES
- Indexed: YES
- Used By: CloudKit

**Note**: CategoryDeduplicator (Phase 3.8) already uses householdKey-based logic

---

### **Phase 0.5: Add Household Relationship to PlannedMeal** (30 minutes)

**Entity**: PlannedMeal

**Add Relationship**:
- Name: `household`
- Destination: `Household`
- Type: To One
- Optional: **YES**
- Delete Rule: Nullify
- Inverse: `plannedMeals` (on Household)

**Add Attribute**:
- Name: `householdKey`
- Type: String
- Optional: YES
- Indexed: YES
- Used By: CloudKit

---

### **Phase 0.6: Add Inverse Relationships to Household** (30 minutes)

**Entity**: Household (already exists from M7.2.2)

**Add To-Many Relationships**:

1. **recipes**
   - Destination: Recipe
   - Type: To Many
   - Optional: YES
   - Delete Rule: Cascade
   - Inverse: `household`

2. **ingredientTemplates**
   - Destination: IngredientTemplate
   - Type: To Many
   - Optional: YES
   - Delete Rule: Cascade
   - Inverse: `household`

3. **categories**
   - Destination: Category
   - Type: To Many
   - Optional: YES
   - Delete Rule: Cascade
   - Inverse: `household`

4. **plannedMeals**
   - Destination: PlannedMeal
   - Type: To Many
   - Optional: YES
   - Delete Rule: Cascade
   - Inverse: `household`

**Why Cascade**: When household is deleted, all shared data should be deleted too

---

### **Phase 0.7: Run Migration Validation Tests** (30 minutes)

**Goal**: Confirm lightweight migration will work

**Steps**:
1. Build the project (⌘B)
2. Run MigrationValidationTests (⌘U)
3. Verify all tests pass:
   - ✅ testModelVersion2CanMigrateFromVersion1
   - ✅ testNewRelationshipsAreOptional
   - ✅ testNoRequiredAttributesDeleted
   - ✅ testLightweightMigrationPossible

**If tests fail**:
- Check that all household relationships are Optional: YES
- Verify no required attributes were deleted
- Confirm inverse relationships are properly configured

---

### **Phase 0.8: Test Migration with Sample Data** (30 minutes)

**Goal**: Verify existing data migrates cleanly

**Steps**:
1. Delete app from simulator (to start fresh with model v1)
2. Check out commit before model changes: `git stash`
3. Run app, create 2-3 test recipes
4. Stop app
5. Return to model v2: `git stash pop`
6. Run app again
7. Verify recipes still load correctly (household will be nil, that's expected)

**Success Criteria**:
- App launches without crashing
- Existing recipes are visible
- No data loss
- Console shows no Core Data errors

---

## 🎯 **AFTER PHASE 0 COMPLETE**

### **Git Workflow**:
```bash
# Commit Phase 0 work
git add forager.xcdatamodeld/
git commit -m "M7.2.3 Phase 0: Core Data model v2 with household relationships

✅ Model Changes:
- Created model version 2
- Added household relationship to Recipe, IngredientTemplate, Category, PlannedMeal
- Added householdKey string attributes (indexed, CloudKit-compatible)
- Added inverse relationships to Household (cascade delete)

✅ Validation:
- All relationships optional (migration-safe)
- Migration tests passing
- Sample data migrates cleanly

📊 Metrics:
- Estimated: 3-4h
- Actual: [X]h

🎯 Next: Phase 2 - Scope-based store assignment (4-5h)"

git push origin feature/M7.2.3-prep-phase
```

### **Update Documentation**:
1. Mark Phase 0 ✅ COMPLETE in `current-story.md`
2. Update progress: 33% → 48% (6.5h → 10h)
3. Update `next-prompt.md` for Phase 2

### **Begin Phase 2** (if time permits):
- Read PRD v2.2 Phase 2 section (lines 425-582)
- Implement DataScope, ScopeProvider, ManagedObjectFactory
- Expected duration: 4-5 hours

---

## 📚 **KEY REFERENCES**

**PRD v2.2 FINAL**: `docs/prds/m7.2.3-cloudkit-hardening-household-repositories.md`
- Lines 325-423: Phase 0 (Core Data model changes) ← **READ THIS**
- Lines 425-582: Phase 2 (Scope-based store assignment)
- Lines 1511-1564: Version history & polish integrations

**Key Concepts**:
- **Optional relationships**: Required for lightweight migration from v1 → v2
- **householdKey attributes**: Enable semantic deduplication without relationship traversal
- **Cascade delete**: Household deletion removes all associated shared data
- **Nullify delete**: Entity deletion doesn't affect household

---

## 🚨 **CRITICAL REMINDERS**

1. **All household relationships MUST be Optional: YES** - Non-optional breaks migration
2. **Test migration before proceeding** - MigrationValidationTests must pass
3. **Use householdKey for deduplication** - Don't traverse relationships in predicates
4. **Commit after each sub-phase** - Every 30min for safety
5. **Follow PRD v2.2 exactly** - It's externally validated, don't improvise

---

**Version**: January 2, 2026 - Phase 0 Ready  
**Status**: 🚀 Prep Phase complete, Core Data model changes next  
**Progress**: 33% complete (6.5h / 19.5h)
