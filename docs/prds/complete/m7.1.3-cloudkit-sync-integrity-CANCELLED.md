# Product Requirements Document: M7.1.3 CloudKit Sync Integrity

**Milestone:** M7.1.3 CloudKit Sync Integrity - Semantic Uniqueness Architecture  
**Version:** 4.1 - Production-Ready Implementation  
**Date:** December 13, 2025  
**Status:** 🚀 READY TO START (Fresh Start After Lessons Learned)  
**Estimated Time:** 11-15 hours (implementation + testing + comprehensive documentation)

---

## 📋 EXECUTIVE SUMMARY

### **The Problem**

Multi-device CloudKit testing revealed a fundamental architectural issue: **CloudKit Core Data creates duplicate entities across devices** when multiple devices create semantically identical objects.

**Example:**
```
Device A creates: Category(UUID=123, displayName="Produce")
Device B creates: Category(UUID=456, displayName="Produce")

CloudKit sees: Different UUIDs → Accepts both as valid records
Both sync back to both devices → App has TWO "Produce" categories
Dictionary creation crashes: "Fatal error: Duplicate values for key: 'Produce'"
```

**Root Cause:** CloudKit Core Data only understands UUID uniqueness, not "semantic uniqueness" (same name = same thing).

---

### **The Solution: Three-Layer Architecture**

**Layer 1: Core Data Model - Semantic Keys**
- Add semantic key fields (normalizedName, canonicalName, slotKey)
- Index for fast lookups
- Standardize field naming (name → displayName across all entities)
- Two-stage migration (optional → required) for safe CloudKit deployment

**Layer 2: Repository Pattern - Get-or-Create**
- ALWAYS query by semantic key first
- Only create if doesn't exist
- Guaranteed single source of truth
- Canonical normalization helpers

**Layer 3: Application Layer - Use Repositories**
- NO direct `Category(context:)` instantiation
- ALL creation goes through repositories
- Clean separation of concerns

---

### **Scope (Simplified - No Production Data)**

Since forager has no real users or production data, we implement **clean architecture without complex deduplication**:

**Core Entities with Semantic Uniqueness:**
- **Category:** One per normalized name (e.g., "produce")
- **IngredientTemplate:** One per canonical name (e.g., "basil")
- **PlannedMeal:** One per slot (date + mealType, e.g., "2024-12-13-breakfast")

**User-Assisted Detection:**
- **Recipe:** Detect duplicate titles, let user decide (allow intentional duplicates)

**Allow Duplicates by Design:**
- **WeeklyList:** Just a container, no uniqueness needed
- **MealPlan:** Week-long plan container, no uniqueness needed
- **GroceryListItem:** Duplicates intentional (consolidation happens in UI)

---

### **Key Architectural Decisions**

✅ **Two-stage migration** (add fields → populate → add constraints)  
✅ **Canonical normalization helpers** (consistent everywhere)  
✅ **Repository pattern** (prevents duplicates going forward)  
✅ **Field standardization** (name → displayName across all entities)  
✅ **PlannedMeal.mealType** (new field for slot protection)  
✅ **Calendar.current timezone** (meals stay on calendar dates)  
✅ **No deduplication needed** (clean slate, no production data)

---

## 🎯 GOALS & SUCCESS CRITERIA

### **Primary Goals**
1. **Zero Duplicate Creation:** Repository pattern prevents creating semantic duplicates
2. **Field Standardization:** Rename `name` → `displayName` for consistency across entities
3. **User Control:** Recipe duplicates flagged for user resolution, not auto-prevented
4. **Slot Protection:** PlannedMeal enforces one meal per date/mealType combination
5. **Clean Architecture:** No technical debt from quick fixes or workarounds

### **Success Criteria**
- ✅ Multi-device sync creates zero duplicate Categories
- ✅ Multi-device sync creates zero duplicate IngredientTemplates
- ✅ PlannedMeals enforce one meal per slot (date + mealType)
- ✅ Recipe save shows detection dialog if similar recipe exists
- ✅ WeeklyLists, MealPlans, GroceryListItems allow duplicates as designed
- ✅ All entities use `displayName` consistently (not `name`)
- ✅ All tests pass with 2 physical devices
- ✅ Zero regressions to M1-M7.1.2 features

### **Performance Targets**
- Semantic key lookups: < 0.001s (Core Data indexed queries)
- Repository get-or-create: < 0.01s
- CloudKit sync with semantic uniqueness: < 5s
- UI operations: < 0.5s (existing standard maintained)

---

## 🏗️ ARCHITECTURE OVERVIEW

### **Three-Layer Pattern**

```
┌─────────────────────────────────────────────────────────┐
│ Layer 1: Core Data Model - Semantic Keys               │
│ - normalizedName, canonicalName, slotKey               │
│ - Uniqueness constraints on semantic keys              │
│ - Indexed for fast lookups                             │
│ - displayName standardized across all entities         │
└─────────────────────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│ Layer 2: Repository Pattern - Get-or-Create            │
│ - ALWAYS query by semantic key first                   │
│ - Only create if genuinely doesn't exist               │
│ - Guaranteed single source of truth                    │
│ - Canonical normalization helpers                      │
└─────────────────────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│ Layer 3: Application Layer - Use Repositories          │
│ - NO direct Category(context:) instantiation           │
│ - NO direct IngredientTemplate(context:) creation      │
│ - ALL creation goes through repositories               │
└─────────────────────────────────────────────────────────┘
```

### **Semantic Key Strategy by Entity**

| Entity | Semantic Key | Strategy | Constraint | Notes |
|--------|-------------|----------|------------|-------|
| **Category** | `normalizedName` | Repository get-or-create | ✅ Unique | Lowercase, trimmed |
| **IngredientTemplate** | `canonicalName` | Repository get-or-create | ✅ Unique | Normalized, singular |
| **PlannedMeal** | `slotKey` | Repository get-or-create | ✅ Unique | "YYYY-MM-DD-mealType" |
| **Recipe** | `titleKey` | Detect + user dialog | ❌ No constraint | User decides |
| **WeeklyList** | None | Direct creation | ❌ No constraint | Just a container |
| **MealPlan** | None | Direct creation | ❌ No constraint | Week-long plan |
| **GroceryListItem** | None | Direct creation | ❌ No constraint | Duplicates intentional |

---

## 🔧 TWO-STAGE MIGRATION STRATEGY

### **Why Two Stages?**

**Problem:** Adding uniqueness constraints before all devices sync causes `NSConstraintConflictError`:

```
Time T0: Device A upgrades → adds uniqueness constraints
Time T1: Device B hasn't upgraded yet → still creating duplicates
Time T2: CloudKit syncs Device B's duplicates to Device A
Time T3: Device A receives duplicate → constraint violation → CRASH
```

**Solution:** Separate field addition from constraint enforcement.

---

### **Stage A: Add Semantic Keys (Model Version 2)**

**Goal:** Introduce fields, populate them, let all devices sync clean data

**Core Data Model Changes:**
```swift
// Add fields as OPTIONAL (allow nil during transition)
Category {
    displayName: String?        // Renamed from 'name'
    normalizedName: String?     // NEW - semantic key (lowercase, trimmed)
    updatedAt: Date?           // NEW - conflict resolution
}

IngredientTemplate {
    displayName: String?        // Renamed from 'name'
    canonicalName: String?      // NEW - semantic key (normalized)
    createdAt: Date?           // NEW - tracking
    updatedAt: Date?           // NEW - conflict resolution
}

PlannedMeal {
    date: Date?                // Existing
    mealType: String?          // NEW - "breakfast", "lunch", "dinner", "snack"
    slotKey: String?           // NEW - semantic key (date + mealType)
    createdAt: Date?           // NEW - tracking
    recipe: Recipe?            // Existing relationship
    mealPlan: MealPlan?        // Existing relationship
}

Recipe {
    displayName: String?        // Renamed from 'title'
    titleKey: String?          // NEW - for duplicate detection (normalized)
    createdAt: Date?           // Existing (ensure present)
}

// NO constraints yet - just field addition and population
```

**Migration Code Structure:**
```swift
// In Persistence.swift
private func performStageAMigration(in context: NSManagedObjectContext) {
    let stageAKey = "M7.1.3.StageA.Completed"
    guard !UserDefaults.standard.bool(forKey: stageAKey) else {
        print("ℹ️ Stage A migration already completed")
        return
    }
    
    print("🚀 Stage A: Adding and populating semantic key fields...")
    
    // Populate semantic keys for existing entities
    populateCategorySemanticKeys(in: context)
    populateIngredientTemplateSemanticKeys(in: context)
    populatePlannedMealSemanticKeys(in: context)
    populateRecipeSemanticKeys(in: context)
    
    try? context.save()
    UserDefaults.standard.set(true, forKey: stageAKey)
    
    print("✅ Stage A complete - fields added and populated")
}
```

---

### **Stage B: Add Constraints (Model Version 3)**

**Goal:** Enforce uniqueness after all devices have clean data

**When to deploy:** After 100% of devices are on Model Version 2 and have clean data

**Core Data Model Changes:**
```swift
Category {
    displayName: String        // NOW REQUIRED (not optional)
    normalizedName: String     // NOW REQUIRED + UNIQUE CONSTRAINT
    updatedAt: Date           // NOW REQUIRED
}

IngredientTemplate {
    displayName: String        // NOW REQUIRED
    canonicalName: String      // NOW REQUIRED + UNIQUE CONSTRAINT
    createdAt: Date           // NOW REQUIRED
    updatedAt: Date           // NOW REQUIRED
}

PlannedMeal {
    date: Date                // NOW REQUIRED
    mealType: String          // NOW REQUIRED
    slotKey: String           // NOW REQUIRED + UNIQUE CONSTRAINT
    createdAt: Date           // NOW REQUIRED
}

Recipe {
    displayName: String        // NOW REQUIRED
    titleKey: String          // NOW REQUIRED (no constraint - user decides)
    createdAt: Date           // NOW REQUIRED
}
```

**Note:** Stage B is NOT part of this PRD. It's a separate future migration after all devices sync Stage A.

---

## 📋 PHASE BREAKDOWN

### **Phase 1: Semantic Key Implementation (8-10 hours)**

This is the core of M7.1.3. Three sub-phases:

---

#### **Phase 1.1: Add Fields & Populate (6-8 hours)**

**Part 1: Create Model Version 2 & Add Fields (2.5 hours)**

**Steps:**
1. Create Model Version 2 in Xcode (30 min)
   - Editor → Add Model Version → "forager 2"
   - Set as current model version
   - Build → should succeed (no changes yet)
   - Commit: "M7.1.3 Phase 1.1 Part 1: Create Model Version 2"

2. Add semantic key fields ONE ENTITY AT A TIME (2 hours)

**Category (30 min):**
```swift
// Add to Category entity in Model Version 2:
normalizedName: String? Optional  // Semantic key
updatedAt: Date? Optional         // Conflict resolution

// Add index on normalizedName
```
- Build, fix Category-related errors only
- Test app launch
- Commit: "M7.1.3: Add normalizedName to Category"

**IngredientTemplate (30 min):**
```swift
// Add to IngredientTemplate entity:
canonicalName: String? Optional   // Semantic key
createdAt: Date? Optional         // Tracking
updatedAt: Date? Optional         // Conflict resolution

// Add index on canonicalName
```
- Build, fix IngredientTemplate errors only
- Test app launch
- Commit: "M7.1.3: Add canonicalName to IngredientTemplate"

**PlannedMeal (30 min):**
```swift
// Add to PlannedMeal entity:
mealType: String? Optional        // "breakfast", "lunch", "dinner", "snack"
slotKey: String? Optional         // Semantic key
createdAt: Date? Optional         // Tracking

// Add index on slotKey
```
- Build, fix PlannedMeal errors only
- Test app launch
- Commit: "M7.1.3: Add slotKey and mealType to PlannedMeal"

**Recipe (30 min):**
```swift
// Add to Recipe entity:
titleKey: String? Optional        // For duplicate detection
// createdAt should already exist from earlier milestones

// Add index on titleKey
```
- Build, fix Recipe errors only
- Test app launch
- Commit: "M7.1.3: Add titleKey to Recipe"

**Why one entity at a time:**
- Smaller blast radius for errors
- Easier to debug specific entity issues
- Clear git history for rollback
- Can test after each entity
- Prevents cascading build errors

---

**Part 2: Populate Semantic Keys (2-3 hours)**

**Implementation Location:** `forager/Persistence.swift`

**Step 1: Category Population (30 min)**
```swift
private func populateCategorySemanticKeys(in context: NSManagedObjectContext) {
    let request: NSFetchRequest<Category> = Category.fetchRequest()
    
    guard let categories = try? context.fetch(request) else { 
        print("⚠️ Failed to fetch categories for population")
        return 
    }
    
    var populatedCount = 0
    for category in categories {
        guard let displayName = category.displayName, 
              !displayName.isEmpty else { 
            print("⚠️ Skipping category with nil/empty displayName")
            continue 
        }
        
        // Use helper function (to be created in Part 3)
        category.normalizedName = Category.normalizedName(from: displayName)
        category.updatedAt = Date()
        populatedCount += 1
    }
    
    print("✅ Populated normalizedName for \(populatedCount) categories")
}
```

**Test:**
- Call function in migration
- Delete app
- Run app
- Check console: "✅ Populated normalizedName for X categories"
- Verify in Core Data inspector
- Commit: "M7.1.3: Populate Category normalizedName"

**Step 2: IngredientTemplate Population (30 min)**
```swift
private func populateIngredientTemplateSemanticKeys(in context: NSManagedObjectContext) {
    let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
    
    guard let templates = try? context.fetch(request) else {
        print("⚠️ Failed to fetch templates for population")
        return
    }
    
    var populatedCount = 0
    for template in templates {
        guard let displayName = template.displayName,
              !displayName.isEmpty else {
            print("⚠️ Skipping template with nil/empty displayName")
            continue
        }
        
        // Use helper function (to be created in Part 3)
        template.canonicalName = IngredientTemplate.canonicalName(from: displayName)
        template.createdAt = template.createdAt ?? Date()
        template.updatedAt = Date()
        populatedCount += 1
    }
    
    print("✅ Populated canonicalName for \(populatedCount) templates")
}
```

**Step 3: PlannedMeal Population (30 min)**
```swift
private func populatePlannedMealSemanticKeys(in context: NSManagedObjectContext) {
    let request: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
    
    guard let meals = try? context.fetch(request) else {
        print("⚠️ Failed to fetch planned meals for population")
        return
    }
    
    var populatedCount = 0
    for meal in meals {
        guard let date = meal.date else {
            print("⚠️ Skipping planned meal with nil date")
            continue
        }
        
        // Infer mealType if not set (default to "dinner")
        if meal.mealType == nil || meal.mealType?.isEmpty == true {
            meal.mealType = "dinner"
        }
        
        guard let mealType = meal.mealType else { continue }
        
        // Use helper function (to be created in Part 3)
        meal.slotKey = PlannedMeal.slotKey(date: date, mealType: mealType)
        meal.createdAt = meal.createdAt ?? Date()
        populatedCount += 1
    }
    
    print("✅ Populated slotKey for \(populatedCount) planned meals")
}
```

**Step 4: Recipe Population (30 min)**
```swift
private func populateRecipeSemanticKeys(in context: NSManagedObjectContext) {
    let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
    
    guard let recipes = try? context.fetch(request) else {
        print("⚠️ Failed to fetch recipes for population")
        return
    }
    
    var populatedCount = 0
    for recipe in recipes {
        guard let displayName = recipe.displayName,
              !displayName.isEmpty else {
            print("⚠️ Skipping recipe with nil/empty displayName")
            continue
        }
        
        // Use helper function (to be created in Part 3)
        recipe.titleKey = Recipe.titleKey(from: displayName)
        recipe.createdAt = recipe.createdAt ?? Date()
        populatedCount += 1
    }
    
    print("✅ Populated titleKey for \(populatedCount) recipes")
}
```

**Step 5: Wire Up Migration (30 min)**
```swift
// In Persistence.swift init or loadPersistentStores completion
private func performStageAMigration(in context: NSManagedObjectContext) {
    let key = "M7.1.3.StageA.Completed"
    
    // Only run once per installation
    guard !UserDefaults.standard.bool(forKey: key) else {
        print("ℹ️ Stage A migration already completed")
        return
    }
    
    print("🚀 Starting Stage A migration (semantic key population)...")
    
    populateCategorySemanticKeys(in: context)
    populateIngredientTemplateSemanticKeys(in: context)
    populatePlannedMealSemanticKeys(in: context)
    populateRecipeSemanticKeys(in: context)
    
    do {
        if context.hasChanges {
            try context.save()
        }
        UserDefaults.standard.set(true, forKey: key)
        print("✅ Stage A migration complete - all semantic keys populated")
    } catch {
        print("❌ Stage A migration failed: \(error)")
        // Don't set flag - will retry next launch
    }
}

// Call from container setup:
container.loadPersistentStores { description, error in
    // ... existing error handling ...
    
    // Run migration in background
    self.container.performBackgroundTask { context in
        self.performStageAMigration(in: context)
    }
}
```

---

**Part 3: Normalization Helpers (1-2 hours)**

**Purpose:** Create SINGLE SOURCE OF TRUTH normalization functions used by:
- Population functions (Part 2)
- Repository pattern (Phase 1.2)
- Application code (everywhere)

**File:** `forager/Category+Extensions.swift`
```swift
import Foundation
import CoreData

extension Category {
    /// Single source of truth for normalizing category names
    /// Used by: Repository, population, and all category creation
    /// 
    /// Normalization rules:
    /// - Lowercase for case-insensitive matching
    /// - Trim whitespace for consistent keys
    /// 
    /// Examples:
    /// - "Produce" → "produce"
    /// - "  Dairy  " → "dairy"
    /// - "MEAT & SEAFOOD" → "meat & seafood"
    static func normalizedName(from displayName: String) -> String {
        displayName
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Safe access to displayName with fallback
    /// Use this instead of force unwrapping or optional chaining
    var safeDisplayName: String {
        displayName ?? "Uncategorized"
    }
}
```

**File:** `forager/IngredientTemplate+Extensions.swift`
```swift
import Foundation
import CoreData

extension IngredientTemplate {
    /// Single source of truth for canonical ingredient names
    /// 
    /// Normalization rules:
    /// - Lowercase for case-insensitive matching
    /// - Trim whitespace
    /// - TODO Phase 1.2+: Handle plurals (tomatoes → tomato)
    /// - TODO Phase 1.2+: Handle variations (roma tomato → tomato)
    /// 
    /// Examples:
    /// - "Basil" → "basil"
    /// - "  Roma Tomatoes  " → "roma tomatoes"
    /// - "GARLIC CLOVES" → "garlic cloves"
    static func canonicalName(from displayName: String) -> String {
        let cleaned = displayName
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // TODO Phase 1.2+: Add stemming for plurals
        // TODO Phase 1.2+: Add common substitution mapping
        
        return cleaned
    }
    
    /// Safe access to displayName with fallback
    var safeDisplayName: String {
        displayName ?? "Unknown Ingredient"
    }
}
```

**File:** `forager/PlannedMeal+Extensions.swift`
```swift
import Foundation
import CoreData

extension PlannedMeal {
    /// Single source of truth for meal slot keys
    /// 
    /// Format: "YYYY-MM-DD-mealType"
    /// Uses Calendar.current timezone to keep meals on calendar dates
    /// 
    /// Examples:
    /// - Date(2024-12-13 18:00 UTC), "dinner" → "2024-12-13-dinner"
    /// - Date(2024-12-13 07:00 UTC), "breakfast" → "2024-12-13-breakfast"
    /// 
    /// Why ISO8601 date format:
    /// - Unambiguous, sortable
    /// - No timezone confusion
    /// - Consistent across devices
    static func slotKey(date: Date, mealType: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]  // YYYY-MM-DD only
        formatter.timeZone = Calendar.current.timeZone  // Use user's timezone
        
        let dateString = formatter.string(from: date)
        let normalizedMealType = mealType.lowercased()
        
        return "\(dateString)-\(normalizedMealType)"
    }
    
    /// Valid meal types for validation
    static let validMealTypes = ["breakfast", "lunch", "dinner", "snack"]
    
    /// Validate mealType is one of the accepted values
    static func isValidMealType(_ mealType: String) -> Bool {
        validMealTypes.contains(mealType.lowercased())
    }
}
```

**File:** `forager/Recipe+Extensions.swift`
```swift
import Foundation
import CoreData

extension Recipe {
    /// Single source of truth for recipe title keys (duplicate detection)
    /// 
    /// Note: This is for DETECTION only, not uniqueness enforcement
    /// Users can intentionally create duplicate recipe names
    /// 
    /// Normalization rules:
    /// - Lowercase for case-insensitive comparison
    /// - Trim whitespace
    /// 
    /// Examples:
    /// - "Chicken Parmesan" → "chicken parmesan"
    /// - "  Mom's Lasagna  " → "mom's lasagna"
    static func titleKey(from displayName: String) -> String {
        displayName
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Safe access to displayName with fallback
    var safeDisplayName: String {
        displayName ?? "Untitled Recipe"
    }
}
```

**Update population functions to use helpers:**
```swift
// In populateCategorySemanticKeys:
category.normalizedName = Category.normalizedName(from: displayName)

// In populateIngredientTemplateSemanticKeys:
template.canonicalName = IngredientTemplate.canonicalName(from: displayName)

// In populatePlannedMealSemanticKeys:
meal.slotKey = PlannedMeal.slotKey(date: date, mealType: mealType)

// In populateRecipeSemanticKeys:
recipe.titleKey = Recipe.titleKey(from: displayName)
```

**Commit after each extension:**
- "M7.1.3: Add Category normalization helpers"
- "M7.1.3: Add IngredientTemplate normalization helpers"
- "M7.1.3: Add PlannedMeal normalization helpers"
- "M7.1.3: Add Recipe normalization helpers"

---

**Part 4: Test Migration (1 hour)**

**Test Checklist:**

**1. Fresh Install Test (20 min)**
```
Steps:
1. Delete app from device/simulator completely
2. Run app from Xcode
3. Check console logs

Expected output:
"🚀 Starting Stage A migration (semantic key population)..."
"✅ Populated normalizedName for X categories"
"✅ Populated canonicalName for Y templates"
"✅ Populated slotKey for Z planned meals"
"✅ Populated titleKey for W recipes"
"✅ Stage A migration complete - all semantic keys populated"

4. Verify app doesn't crash
5. Navigate through all screens
6. Create new category, template, recipe
```

**2. Idempotency Test (10 min)**
```
Steps:
1. Run app again (don't delete)
2. Check console logs

Expected output:
"ℹ️ Stage A migration already completed"

3. Verify no duplicate work
4. Verify UserDefaults flag working
```

**3. Data Validation Test (15 min)**
```
Steps:
1. Open Core Data inspector (or use test view)
2. Inspect Category entities:
   - displayName present
   - normalizedName populated (lowercase, trimmed)
   - updatedAt populated
3. Inspect IngredientTemplate entities:
   - displayName present
   - canonicalName populated
   - createdAt/updatedAt populated
4. Inspect PlannedMeal entities:
   - date present
   - mealType present
   - slotKey populated (format: YYYY-MM-DD-mealtype)
   - createdAt populated
5. Inspect Recipe entities:
   - displayName present
   - titleKey populated
   - createdAt populated
```

**4. App Functionality Test (15 min)**
```
Test all major features still work:
- ✅ Create/edit/delete categories
- ✅ Create/edit/delete grocery items
- ✅ Create/edit/delete recipes
- ✅ Create/edit/delete meal plans
- ✅ Add items to weekly lists
- ✅ Navigate all screens
- ✅ No crashes, no errors
```

**If ALL tests pass:**
```bash
git add -A
git commit -m "M7.1.3 Phase 1.1 COMPLETE: Semantic key fields added and populated

✅ All 4 parts complete:
- Part 1: Fields added to 4 entities (2.5h actual)
- Part 2: Population functions implemented (2.5h actual)
- Part 3: Normalization helpers created (1h actual)
- Part 4: Migration tested and validated (1h actual)

Total: 7 hours actual (within 6-8 hour estimate)

📊 Results:
- Model Version 2 created
- All semantic keys populated on migration
- All normalization helpers working
- Zero regressions
- App launches and functions normally

🎯 Next: Phase 1.2 Repository Pattern (2-3 hours)"

git push origin feature/M7.1.3-phase1.1-fresh-start
```

---

#### **Phase 1.2: Repository Pattern (2-3 hours)**

**Purpose:** Implement get-or-create pattern to prevent duplicate creation going forward

**Files to create:**
- `forager/Repositories/CategoryRepository.swift`
- `forager/Repositories/IngredientTemplateRepository.swift`
- `forager/Repositories/PlannedMealRepository.swift`

**CategoryRepository.swift (30 min):**
```swift
import Foundation
import CoreData

struct CategoryRepository {
    /// Get existing category by normalized name, or create new one
    /// This is the ONLY way categories should be created in the app
    ///
    /// - Parameters:
    ///   - displayName: User-facing category name
    ///   - context: NSManagedObjectContext to use
    /// - Returns: Existing or newly created Category
    static func getOrCreate(displayName: String, in context: NSManagedObjectContext) -> Category {
        let normalized = Category.normalizedName(from: displayName)
        
        // Query by semantic key first
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "normalizedName == %@", normalized)
        request.fetchLimit = 1
        
        // Return existing if found
        if let existing = try? context.fetch(request).first {
            print("📦 Category '\(displayName)' already exists (normalized: '\(normalized)')")
            return existing
        }
        
        // Create new if doesn't exist
        print("✨ Creating new category '\(displayName)' (normalized: '\(normalized)')")
        let category = Category(context: context)
        category.displayName = displayName
        category.normalizedName = normalized
        category.updatedAt = Date()
        
        return category
    }
}
```

**IngredientTemplateRepository.swift (30 min):**
```swift
import Foundation
import CoreData

struct IngredientTemplateRepository {
    /// Get existing template by canonical name, or create new one
    /// This is the ONLY way templates should be created in the app
    ///
    /// - Parameters:
    ///   - displayName: User-facing ingredient name
    ///   - context: NSManagedObjectContext to use
    /// - Returns: Existing or newly created IngredientTemplate
    static func getOrCreate(displayName: String, in context: NSManagedObjectContext) -> IngredientTemplate {
        let canonical = IngredientTemplate.canonicalName(from: displayName)
        
        // Query by semantic key first
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "canonicalName == %@", canonical)
        request.fetchLimit = 1
        
        // Return existing if found
        if let existing = try? context.fetch(request).first {
            print("📦 Template '\(displayName)' already exists (canonical: '\(canonical)')")
            return existing
        }
        
        // Create new if doesn't exist
        print("✨ Creating new template '\(displayName)' (canonical: '\(canonical)')")
        let template = IngredientTemplate(context: context)
        template.displayName = displayName
        template.canonicalName = canonical
        template.createdAt = Date()
        template.updatedAt = Date()
        
        return template
    }
}
```

**PlannedMealRepository.swift (45 min):**
```swift
import Foundation
import CoreData

struct PlannedMealRepository {
    /// Get existing planned meal by slot key, or create new one
    /// Enforces one meal per date/mealType combination
    ///
    /// - Parameters:
    ///   - date: Date of the meal
    ///   - mealType: Type of meal (breakfast/lunch/dinner/snack)
    ///   - recipe: Recipe to plan
    ///   - mealPlan: Parent meal plan
    ///   - context: NSManagedObjectContext to use
    /// - Returns: Existing or newly created PlannedMeal
    static func getOrCreate(
        date: Date,
        mealType: String,
        recipe: Recipe?,
        mealPlan: MealPlan?,
        in context: NSManagedObjectContext
    ) -> PlannedMeal {
        // Validate meal type
        guard PlannedMeal.isValidMealType(mealType) else {
            print("⚠️ Invalid meal type: '\(mealType)', defaulting to 'dinner'")
            return getOrCreate(date: date, mealType: "dinner", recipe: recipe, mealPlan: mealPlan, in: context)
        }
        
        let slotKey = PlannedMeal.slotKey(date: date, mealType: mealType)
        
        // Query by semantic key first
        let request: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        request.predicate = NSPredicate(format: "slotKey == %@", slotKey)
        request.fetchLimit = 1
        
        // Return existing if found (update recipe if different)
        if let existing = try? context.fetch(request).first {
            print("📦 Meal slot '\(slotKey)' already exists")
            
            // Update recipe if changed
            if existing.recipe != recipe {
                print("🔄 Updating recipe for slot '\(slotKey)'")
                existing.recipe = recipe
            }
            
            return existing
        }
        
        // Create new if doesn't exist
        print("✨ Creating new planned meal for slot '\(slotKey)'")
        let meal = PlannedMeal(context: context)
        meal.date = date
        meal.mealType = mealType.lowercased()
        meal.slotKey = slotKey
        meal.recipe = recipe
        meal.mealPlan = mealPlan
        meal.createdAt = Date()
        
        return meal
    }
}
```

**Update Application Code to Use Repositories (45 min):**

Find all instances of:
- `Category(context:)` → Replace with `CategoryRepository.getOrCreate`
- `IngredientTemplate(context:)` → Replace with `IngredientTemplateRepository.getOrCreate`
- Direct PlannedMeal creation → Replace with `PlannedMealRepository.getOrCreate`

**Testing (30 min):**
- Delete app
- Run app
- Create category "Produce" on Device A
- Create category "produce" on Device A (should return existing)
- Sync to Device B
- Create category "PRODUCE" on Device B (should return existing)
- Verify only ONE "Produce" category exists total

**Commit:**
```bash
git commit -m "M7.1.3 Phase 1.2 COMPLETE: Repository pattern implemented

✅ Created repositories:
- CategoryRepository (get-or-create by normalizedName)
- IngredientTemplateRepository (get-or-create by canonicalName)
- PlannedMealRepository (get-or-create by slotKey)

✅ Updated application code:
- All Category creation uses repository
- All IngredientTemplate creation uses repository
- All PlannedMeal creation uses repository

✅ Testing:
- Duplicate creation prevented
- Multi-device sync creates single entities
- All existing features work

Time: 2.5 hours actual (within 2-3 hour estimate)

🎯 Next: Phase 1.3 Uniqueness Constraints (1-2 hours)"
```

---

#### **Phase 1.3: Add Uniqueness Constraints (1-2 hours)**

**⚠️ IMPORTANT:** Only proceed with this phase AFTER confirming:
- Phase 1.2 complete and working
- Multi-device sync tested with repositories
- Zero duplicate creation observed

**Purpose:** Add database-level enforcement of semantic uniqueness

**Steps:**

**1. Create Model Version 3 (15 min)**
- Editor → Add Model Version → "forager 3"
- Set as current model version
- Build → should succeed (no changes yet)

**2. Add Uniqueness Constraints (30 min)**

**Category:**
```
In forager 3.xcdatamodel:
- Select Category entity
- Constraints section
- Add constraint: normalizedName
```

**IngredientTemplate:**
```
- Select IngredientTemplate entity
- Add constraint: canonicalName
```

**PlannedMeal:**
```
- Select PlannedMeal entity
- Add constraint: slotKey
```

**Recipe:**
```
NO CONSTRAINT (user can have duplicate recipe names intentionally)
```

**3. Make Fields Required (15 min)**

**For Category, IngredientTemplate, PlannedMeal, Recipe:**
- Change semantic key fields from Optional to Required
- Change timestamp fields from Optional to Required
- displayName → required

**4. Migration Code (30 min)**

```swift
private func performStageBMigration(in context: NSManagedObjectContext) {
    let stageBKey = "M7.1.3.StageB.Completed"
    guard !UserDefaults.standard.bool(forKey: stageBKey) else {
        print("ℹ️ Stage B migration already completed")
        return
    }
    
    print("🚀 Starting Stage B migration (adding constraints)...")
    
    // Verify all entities have semantic keys populated
    let issues = validateSemanticKeys(in: context)
    
    if !issues.isEmpty {
        print("❌ Cannot add constraints - found entities without semantic keys:")
        issues.forEach { print("  - \($0)") }
        print("⚠️ Run Stage A migration first")
        return
    }
    
    // If validation passes, constraints are already in model
    // Just need to mark complete
    UserDefaults.standard.set(true, forKey: stageBKey)
    print("✅ Stage B migration complete - constraints active")
}
```

**5. Test Constraint Enforcement (15 min)**

```
Steps:
1. Delete app
2. Run app (Stages A and B run)
3. Try to create duplicate category directly:
   Category(context:)
   category.displayName = "Produce"
   category.normalizedName = "produce"
   save() → Should fail with NSConstraintConflictError
4. Create via repository → Should work (returns existing)
```

**Commit:**
```bash
git commit -m "M7.1.3 Phase 1.3 COMPLETE: Uniqueness constraints added

✅ Model Version 3 created
✅ Constraints added:
- Category.normalizedName (unique)
- IngredientTemplate.canonicalName (unique)
- PlannedMeal.slotKey (unique)
- Recipe.titleKey (NO constraint - user choice)

✅ Fields made required:
- All semantic keys
- All timestamp fields
- All displayName fields

✅ Stage B migration implemented
✅ Constraint validation tested

Time: 1.5 hours actual (within 1-2 hour estimate)

🎯 Next: Phase 2 Multi-Device Sync Testing"
```

---

### **Phase 2: Multi-Device Sync Testing (2-3 hours)**

**Prerequisites:**
- Phase 1 complete (1.1, 1.2, 1.3)
- 2 physical devices on same iCloud account
- App installed on both devices

**Test Scenarios:**

**Scenario 1: Category Sync (20 min)**
```
Device A: Create category "Produce"
Wait 5 seconds
Device B: Verify only ONE "Produce" appears
Device B: Try to create "produce" → Returns existing
Result: Zero duplicates ✅
```

**Scenario 2: Template Sync (20 min)**
```
Device A: Create template "basil"
Wait 5 seconds
Device B: Verify only ONE "basil" appears
Device B: Create template "BASIL" → Returns existing
Result: Zero duplicates ✅
```

**Scenario 3: Planned Meal Sync (20 min)**
```
Device A: Plan "Chicken Pasta" for Dec 13 dinner
Wait 5 seconds
Device B: Verify meal appears
Device B: Try to plan different recipe for Dec 13 dinner
Result: Replaces recipe, no duplicate slots ✅
```

**Scenario 4: Recipe Duplicate Detection (20 min)**
```
Device A: Create recipe "Lasagna"
Device B: Create recipe "Lasagna"
Expected: Dialog shows "Similar recipe exists, create anyway?"
User chooses: Yes → Creates second recipe
Result: User control over duplicates ✅
```

**Scenario 5: Offline Sync (30 min)**
```
Device A: Turn off WiFi
Device A: Create 5 categories
Device A: Turn on WiFi
Wait 10 seconds
Device B: Verify all 5 categories appear
Result: Offline queue works ✅
```

**Scenario 6: Stress Test (30 min)**
```
Device A & B: Simultaneously create 20 categories
Wait 30 seconds
Both devices: Verify ~20 categories (not 40)
Both devices: Verify all categories unique
Result: Concurrent creation handled ✅
```

**Success Criteria:**
- ✅ Zero duplicate categories across devices
- ✅ Zero duplicate templates across devices
- ✅ Zero duplicate planned meal slots across devices
- ✅ Recipe duplicates user-controlled
- ✅ Offline sync works correctly
- ✅ Concurrent creation handled
- ✅ Average sync latency < 5 seconds
- ✅ Zero data loss
- ✅ Zero crashes

**Commit:**
```bash
git commit -m "M7.1.3 Phase 2 COMPLETE: Multi-device sync tested

✅ All 6 test scenarios passed:
- Category sync: Zero duplicates
- Template sync: Zero duplicates
- Planned meal sync: Slot protection working
- Recipe detection: User control working
- Offline sync: Queue working correctly
- Stress test: Concurrent handling working

📊 Metrics:
- Average sync latency: 3.2 seconds (< 5s target)
- Zero data loss across all tests
- Zero duplicate creation across devices
- Zero crashes

Time: 2.5 hours actual (within 2-3 hour estimate)

🎯 M7.1.3 COMPLETE - Ready for production!"
```

---

## ⚠️ CRITICAL SUCCESS FACTORS

### **DO:**
- ✅ Read entire PRD before starting
- ✅ Complete phases in order (1.1 → 1.2 → 1.3 → 2)
- ✅ Complete all 4 parts of Phase 1.1 before Phase 1.2
- ✅ Add fields ONE ENTITY AT A TIME
- ✅ Commit every 15-30 minutes
- ✅ Test after each major step
- ✅ Delete app between tests for clean database
- ✅ Use normalization helpers consistently

### **DON'T:**
- ❌ Skip reading the PRD
- ❌ Jump ahead to testing before phases complete
- ❌ Add constraints before repositories working
- ❌ Write workaround code to hide symptoms
- ❌ Make changes without impact analysis
- ❌ Force unwrap optional fields
- ❌ Create entities directly (use repositories)

---

## 📊 TIME ESTIMATES

**Phase 1.1:** 6-8 hours (add fields, populate, helpers, test)  
**Phase 1.2:** 2-3 hours (repository pattern)  
**Phase 1.3:** 1-2 hours (uniqueness constraints)  
**Phase 2:** 2-3 hours (multi-device testing)  

**Total:** 11-16 hours  
**Conservative estimate:** 13 hours  

---

## 📚 RESOURCES

**Read Before Starting:**
- This PRD (all sections)
- `docs/SESSION-NOTES-2025-12-13-LESSONS-LEARNED.md`
- `docs/architecture/007-core-data-change-process.md`

**Apple Documentation:**
- [NSPersistentCloudKitContainer](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer)
- [CloudKit Sync](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit)
- [Core Data Constraints](https://developer.apple.com/documentation/coredata/modeling_data/configuring_entities)

---

**Status:** 🚀 READY TO START  
**Version:** 4.1 - Production-Ready  
**Last Updated:** December 13, 2025
