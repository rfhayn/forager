# Next Implementation Prompt

**Last Updated**: January 1, 2026  
**For Milestone**: M7.2.3 - CloudKit Hardening & Shared Data Architecture  
**Status**: 🚀 **PREP PHASE READY - External Validation Complete**  
**Estimated Duration**: 1 hour (Prep Phase)

---

## 🚀 **M7.2.3 PREP PHASE - START HERE NEXT SESSION**

**Current State:**
- ✅ PRD v2.2 FINAL ready (1597 lines, externally validated)
- ✅ Complete production-ready code from ChatGPT & Gemini
- ✅ All 4 critical bugs fixed before implementation
- ✅ Phase 1 complete (Persistence decomposition, 5h)
- ✅ Phase 3.8 complete (CategoryDeduplicator, 1h)

**What's Next**: Prep Phase (1 hour)  
**Purpose**: Development infrastructure before Core Data model changes

---

## 📋 **PREP PHASE IMPLEMENTATION GUIDE**

### **Prep Phase A: Store Identity Logging Utility** (30 minutes)

**Goal**: Create utility to log which store objects belong to during development

**Implementation**:
1. Create `Services/Persistence/StoreIdentityLogger.swift` (30 lines)
2. Extension on `NSManagedObject` with `logStoreIdentity()` method
3. Prints: object type, objectID, store name (Private/Shared/Unknown)
4. DEBUG-only compilation (#if DEBUG)

**Usage Pattern**:
```swift
let recipe = Recipe(context: viewContext)
recipe.name = "Test Recipe"
try? viewContext.save()
recipe.logStoreIdentity() // Prints: "Recipe [x-coredata://UUID] → Private Store"
```

**Why**: Essential for debugging Phase 4 (attach-then-share migration). Confirms objects moved from private → shared store correctly.

### **Prep Phase B: Lightweight Migration Validation** (30 minutes)

**Goal**: Ensure Core Data model version 2 will migrate cleanly

**Implementation**:
1. Create `Tests/PersistenceTests/MigrationValidationTests.swift` (50 lines)
2. Load model version 1 (current)
3. Create lightweight mapping model programmatically
4. Verify all entities/attributes/relationships compatible
5. Confirm migration will succeed

**Test Cases**:
- ✅ All entities present in both versions
- ✅ No breaking changes (deleted required attributes, etc.)
- ✅ New relationships are nullable (optional)
- ✅ Lightweight migration possible (no custom mapping needed)

**Why**: Prevents "oh shit" moment in Phase 0 when model changes fail to migrate existing data.

---

## 🎯 **AFTER PREP PHASE COMPLETE**

### **Git Workflow**:
```bash
# Commit Prep Phase work
git add Services/Persistence/StoreIdentityLogger.swift
git add Tests/PersistenceTests/MigrationValidationTests.swift
git commit -m "M7.2.3 Prep Phase: Store logging + migration validation

✅ Utilities:
- StoreIdentityLogger for debugging Phase 4
- MigrationValidationTests for Phase 0 safety

📊 Metrics:
- Estimated: 1h
- Actual: [X]h"

git push
```

### **Update Documentation**:
1. Mark Prep Phase ✅ COMPLETE in `current-story.md`
2. Update `next-prompt.md` for Phase 0
3. Add actual time to progress tracking

### **Begin Phase 0** (if time permits):
- Read PRD v2.2 Phase 0 section (lines 325-423)
- Follow implementation guide
- Expected duration: 3-4 hours

---

## 📚 **KEY REFERENCES**

**PRD v2.2 FINAL**: `docs/prds/m7.2.3-cloudkit-hardening-household-repositories.md`
- Lines 256-317: Prep Phase specifications
- Lines 325-423: Phase 0 (Core Data model changes)
- Lines 1511-1564: Version history & polish integrations

**Production-Ready Code** (from external validation):
- DataScope enum (ObjectID-based)
- HouseholdScoped protocol
- ScopeProvider implementation
- ManagedObjectFactory
- Cross-store validator
- IngredientTemplateDeduplicator (complete)

**Learning Notes**:
- External validation summary: `M7.2.3-EXTERNAL-VALIDATION-COMPLETE.md`
- Integration details: `PRD-v2.2-INTEGRATION-SUMMARY.md`

---

## 🚨 **CRITICAL REMINDERS**

1. **Read PRD v2.2 sections before coding** - Don't improvise
2. **Follow Gemini's exact code** - It's battle-tested
3. **StoreIdentityLogger is DEBUG-only** - Use #if DEBUG
4. **Test migration before Phase 0** - Prevents data loss
5. **Commit frequently** - Every 30min during development

---

**Version**: January 1, 2026 - M7.2.3 Prep Phase Ready  
**Status**: 🚀 External validation complete, Prep Phase next  
**PRD**: PRD v2.2 FINAL (1597 lines, battle-tested)