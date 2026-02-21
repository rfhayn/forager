# M9: Technical Debt & Codebase Optimization - PRD

**Version**: 1.1
**Created**: January 4, 2026
**Status**: PLANNED
**Dependencies**: M7 Complete, M8 Complete
**Estimated Effort**: 137-176 hours (17-22 weeks part-time)

---

## 📋 **EXECUTIVE SUMMARY**

M9 addresses accumulated technical debt in the Forager iOS codebase through systematic refactoring, architectural improvements, and performance optimizations. This milestone will reduce code size by ~25%, eliminate critical performance bottlenecks, and establish patterns that prevent future technical debt.

**Key Outcomes:**
- **Code Reduction**: ~2,000 lines eliminated through deduplication and consolidation
- **Performance**: 50-80% improvement in Core Data query performance
- **Maintainability**: Large views reduced from 1,200+ lines to 400-500 lines
- **Testability**: Dependency injection enables comprehensive unit testing
- **Architecture**: Consistent patterns across services and views

**Why Now?**
- M7 CloudKit work complete - stable foundation for refactoring
- M8 analytics insights inform optimization priorities
- Before M10+ features add more complexity
- Technical debt compounds 15-20% per quarter if unaddressed

---

## 🎯 **OBJECTIVES**

### **Primary Goals**
1. **Eliminate Code Duplication**: Consolidate ~300 lines of duplicated utility functions
2. **Optimize Performance**: Fix N+1 queries, add indexes, implement caching
3. **Reduce Complexity**: Break down 1,000+ line view files into manageable components
4. **Improve Architecture**: Dependency injection, consistent service patterns
5. **Enhance Data Integrity**: Migrate string-based categories to Core Data relationships

### **Secondary Goals**
1. Standardize error handling across all services
2. Implement structured logging framework
3. Add Core Data cascade delete rules
4. Create coding standards documentation
5. Establish PR review checklist

### **Non-Goals**
- UI/UX redesign (M10+)
- New feature development
- Migration to new architecture paradigm (SwiftUI TCA, etc.)
- Third-party framework adoption

---

## 📊 **CURRENT STATE ANALYSIS**

### **Codebase Metrics**
- **Total Swift Files**: 45
- **Total Lines of Code**: ~27,000
- **Average File Size**: 600 lines
- **Largest Files**: RecipeListView (1,204), AddIngredientsToListView (901)
- **Service Layer**: 12 services with inconsistent patterns
- **View Layer**: 25+ views, 8 with 500+ lines

### **Technical Debt Categories**

| Category | Issues | Severity | Est. Effort |
|----------|--------|----------|-------------|
| **Compiler Warnings** | 18 | 2 High, 16 Low | 2-3h |
| Code Duplication | 8 | 4 High, 4 Med | 15-20h |
| Code Size/Complexity | 4 | 3 High, 1 Med | 25-30h |
| Architecture | 6 | 2 High, 4 Med | 45-55h |
| Performance | 3 | 2 High, 1 Med | 10-15h |
| SwiftUI Patterns | 3 | 1 Med, 2 Low | 12-16h |
| Service Layer | 2 | 1 Med, 1 Low | 13-17h |
| Core Data | 3 | 2 High, 1 Med | 15-20h |
| **TOTAL** | **47** | **12 High, 14 Med, 21 Low** | **137-176h** |

---

## 🏗️ **PHASED IMPLEMENTATION PLAN**

### **PHASE 0: Warning Resolution** (45-60 min, 1 session)

**Objective**: Achieve zero-warning build as clean baseline before refactoring

**Why First?**
- Establishes professional code quality baseline
- Prevents warnings from masking new issues during refactoring
- Addresses 2 deprecated API calls and 1 non-exhaustive switch
- Quick win with immediate visibility

> **PRD Staleness Audit (February 21, 2026)**: Original Phase 0 was written January 4, 2026
> and listed warnings for MealPlanDetailView and IngredientTemplateValidationTests — neither
> produces warnings in the current build. The original PRD also missed 3 GroceryListDetailView
> warnings and a non-exhaustive switch in HouseholdService:1178. The warning list below is from
> a fresh `xcodebuild build` on February 21, 2026 and supersedes the original.
>
> **Revised time estimate**: 45-60 min (down from 2-3h). The original PRD allocated 45-60 min
> for researching CloudKit deprecation replacements. Per insights-log entry #57, Apple deprecated
> `discoverUserIdentity` in iOS 17 with **no replacement API**, and `nameComponents` already
> returns nil for the current user on iOS 16+. The fix is simply to remove the deprecated calls
> and rely on existing fallback paths.

---

**All 18 Warnings (grouped by fix type)**

#### Group A: Deprecated CloudKit APIs (2 warnings, ~20 min)

| # | File | Line | Warning |
|---|------|------|---------|
| 1 | `Services/HouseholdService.swift` | 1596 | `discoverUserIdentity(withUserRecordID:completionHandler:)` deprecated |
| 2 | `Services/HouseholdService.swift` | 2072 | `userIdentity(forUserRecordID:)` deprecated |

**Key finding**: Apple deprecated `discoverUserIdentity` in iOS 17 with **NO replacement API**.
Both the completion-handler (line 1596) and async (line 2072) versions are deprecated. The
`nameComponents` property already returns nil for the current user on iOS 16+, so these APIs
are both deprecated AND unreliable.

**Fix**:
- `getCurrentUserInfo()` (line 1582-1638): Replace entire `withCheckedThrowingContinuation`
  block with async `container.userRecordID()`. Use `recordName` as identifier, "Me" as display
  name. The app already prompts users for their display name during household creation — the
  deprecated API was just a pre-fill that usually returned nil anyway.
- `refreshDisplayName()` (line 2067-2085): Remove the Try 1 block that calls
  `userIdentity(forUserRecordID:)`. The existing Try 2 (device name extraction at line 2088)
  becomes the primary path.

**Risk**: Low — both deprecated calls have existing fallback paths that already handle the
common case (nil nameComponents). Removing the deprecated calls just makes the fallback the
primary path.

#### Group B: Unused Variables (8 warnings, ~10 min)

| # | File | Line | Warning | Fix |
|---|------|------|---------|-----|
| 3 | `Services/HouseholdService.swift` | 367 | `householdName` unused in `leaveHousehold()` | Remove assignment |
| 4 | `Services/HouseholdService.swift` | 487 | `householdName` unused in `deleteHousehold()` | Remove assignment |
| 5 | `forager/GroceryListDetailView.swift` | 387 | `originalCompleted` unused | Remove (was planned undo feature) |
| 6 | `forager/GroceryListDetailView.swift` | 388 | `originalDate` unused | Remove (was planned undo feature) |
| 7 | `forager/DatePickerSheet.swift` | 147 | `plan` binding unused | Change to `if mealPlanService.activeMealPlan != nil` |
| 8 | `forager/DatePickerSheet.swift` | 198 | `meal` binding unused | Change to `if mealPlanService.addRecipeToMealPlan(...) != nil` |
| 9 | `forager/ManageCategoriesView.swift` | 402 | `targetCategoryID` unused | Remove assignment |
| 10 | `Services/Persistence/HouseholdScopeProvider.swift` | 169 | `storeID` unused in pattern | Change to `if case .household(let id, _) = scope` |

#### Group C: Unnecessary `await` (3 warnings, ~5 min)

| # | File | Line | Fix |
|---|------|------|-----|
| 11 | `Services/HouseholdService.swift` | 1558 | Remove `await` — `onStatus` closure is not async |
| 12 | `Services/HouseholdService.swift` | 1563 | Same |
| 13 | `Services/HouseholdService.swift` | 2172 | Remove `await` — non-async expression |

#### Group D: Non-exhaustive Switch (2 warnings, ~5 min)

| # | File | Line | Fix |
|---|------|------|-----|
| 14 | `Services/HouseholdService.swift` | 1178 | Add `case .available:` before guard (the guard on line 1176 already handles this case, but the switch inside the guard body doesn't list it — add it for exhaustiveness) |
| 15 | `Services/ShareParticipant.swift` | 82 | Already has `@unknown default` — check if compiler needs explicit `.unknown` case added before the `@unknown default` |

#### Group E: Code Quality (3 warnings, ~5 min)

| # | File | Line | Fix |
|---|------|------|-----|
| 16 | `forager/GroceryListDetailView.swift` | 414 | Assign `withAnimation` result to `_` or restructure |
| 17 | `Services/IngredientTemplateService.swift` | 224 | Change `var result` to `let result` (verify: is it mutated later?) |
| 18 | `Services/Persistence/PersistenceController.swift` | 108 | Remove `as! NSPersistentCloudKitContainer` — casting to same type |

---

**Execution Order:**
1. **Group A first** (deprecated APIs) — highest risk, needs testing
2. **Groups B-E** (mechanical fixes) — low risk, fast
3. **Build verification** — confirm zero warnings
4. **Commit & PR**

**Deliverables:**
- ✅ Zero compiler warnings (down from 18)
- ✅ Deprecated CloudKit APIs removed (no replacement exists)
- ✅ All switch statements exhaustive
- ✅ Clean build baseline established

**Success Metrics:**
| Metric | Before | After |
|--------|--------|-------|
| Compiler warnings | 18 | 0 |
| Deprecation warnings | 2 | 0 |
| Non-exhaustive switch warnings | 2 | 0 |
| Unused variable warnings | 8 | 0 |
| Code quality warnings | 3 | 0 |
| Unnecessary await warnings | 3 | 0 |

**Risk Assessment:**
- **Low**: Deprecated CloudKit calls already have fallback paths that handle the common case.
  Removing the deprecated calls just promotes the fallback to primary.
- **Low**: All other fixes are mechanical cleanup.

**Testing Checklist:**
- [ ] `xcodebuild build` produces zero warnings
- [ ] App launches and household features still work (creation, member display, leave/delete)
- [ ] Share participant display shows correct acceptance status
- [ ] Grocery list toggle/check still works

---

### **PHASE 1: Quick Wins & Critical Fixes** (20-25 hours, 3 weeks)

**Objective**: Address high-impact, low-effort issues with immediate benefits

**M9.1: Utility Consolidation** (6-8 hours)

**Tasks:**
1. **Extract Category Utilities** (2-3h)
   - Create `forager/Extensions/Category+UI.swift`
   - Implement `Category.emoji(for:)` and `Category.color(for:)`
   - Replace 5+ duplicated `categoryEmoji()` functions
   - **Files to modify**: ManageCategoriesView, IngredientsView, GroceryListDetailView, AddListItemView, RecipeListView, AddIngredientsToListView

2. **Extract Quantity Formatting** (2-3h)
   - Create `Services/QuantityFormatter.swift`
   - Centralize `formatToFraction(_:)` logic
   - Add `formatQuantity(value:unit:)` method
   - **Files to modify**: RecipeScalingService, QuantityMergeService, AddIngredientsToListView, MealPlanDetailView

3. **Extract Ingredient Name Parsing** (1-2h)
   - Move `extractCleanIngredientName(from:)` to `IngredientParsingService`
   - **Files to modify**: AddIngredientsToListView, MealPlanDetailView

4. **Testing** (1h)
   - Unit tests for new utility functions
   - Verify all existing functionality unchanged

**Deliverables:**
- ✅ 3 new utility files/extensions
- ✅ ~150 lines of duplicated code eliminated
- ✅ 6+ files simplified
- ✅ 15+ unit tests added

**Success Metrics:**
- Zero regression bugs
- All existing tests pass
- Code coverage ≥ 80% for new utilities

---

**M9.2: Core Data Performance** (8-10 hours)

**Tasks:**
1. **Add Indexes** (2h)
   - Open `forager.xcdatamodeld`
   - Add hash indexes:
     - `IngredientTemplate.name`
     - `IngredientTemplate.canonicalName`
     - `Category.displayName`
     - `Recipe.title`
   - Test query performance improvements

2. **Fix N+1 Queries** (4-5h)
   - **AddIngredientsToListView** (lines 284-310):
     - Batch fetch all templates upfront
     - Create in-memory dictionary lookup
     - Replace individual fetches
   - **Other views with similar patterns**:
     - Identify with Instruments profiling
     - Apply batch fetching pattern

   ```swift
   // Before (N+1 problem)
   for ingredient in ingredients {
       let template = try context.fetch(request).first  // Query per ingredient!
   }

   // After (1 query)
   let allTemplates = try context.fetch(batchRequest)
   let templateDict = Dictionary(uniqueKeysWithValues: allTemplates.map { ($0.name, $0) })
   for ingredient in ingredients {
       let template = templateDict[cleanName]  // Memory lookup
   }
   ```

3. **Implement Template Caching** (2-3h)
   - Add `IngredientTemplateService.templateCache: [String: IngredientTemplate]`
   - Cache lookups for session duration
   - Invalidate on template creation/update
   - Measure cache hit rate

4. **Performance Testing** (1h)
   - Instruments profiling before/after
   - Measure fetch time for 100+ ingredients
   - Document improvements

**Deliverables:**
- ✅ 4 Core Data indexes added
- ✅ N+1 queries eliminated
- ✅ Template caching operational
- ✅ Performance benchmark report

**Success Metrics:**
- Template lookup time: < 10ms (from ~50-100ms)
- Batch ingredient processing: 50-80% faster
- Cache hit rate: > 85% in normal usage

---

**M9.3: Thread Safety Fixes** (4-5 hours)

**Tasks:**
1. **Fix ManageCategoriesView Background Context Issues** (2-3h)
   - **Problem Location**: Lines 534-550
   - Refactor to use object IDs instead of objects
   - Fetch relationships on main thread first
   - Pass IDs to background context

   ```swift
   // Before (UNSAFE)
   PersistenceController.shared.performWrite({ context in
       let category = context.object(with: categoryID) as! Category
       if let items = category.groceryItems {  // ❌ Relationship on background thread
           for item in items { ... }
       }
   })

   // After (SAFE)
   let itemIDs = category.groceryItems?.map { $0.objectID } ?? []
   PersistenceController.shared.performWrite({ context in
       for itemID in itemIDs {
           let item = context.object(with: itemID) as! GroceryItem
           item.categoryEntity = nil
       }
   })
   ```

2. **Audit Other Background Operations** (1-2h)
   - Search for `.perform(` and `.performBackgroundTask(`
   - Verify relationship access patterns
   - Add assertions in DEBUG builds

3. **Testing** (1h)
   - Test category deletion with many items
   - Test under Thread Sanitizer
   - Verify no crashes or warnings

**Deliverables:**
- ✅ Thread safety violations fixed
- ✅ Audit report of background operations
- ✅ Thread Sanitizer clean run

**Success Metrics:**
- Zero "Object was invalidated" crashes
- Thread Sanitizer passes
- Background operations complete successfully

---

**M9.4: Error Handling Standardization** (2-3 hours)

**Tasks:**
1. **Create ServiceError Framework** (1-1.5h)
   - Create `forager/Models/ServiceError.swift`

   ```swift
   enum ServiceError: LocalizedError {
       case coreDataError(Error)
       case cloudKitError(CKError)
       case validationError(String)
       case notFound(String)
       case unauthorized

       var errorDescription: String? {
           switch self {
           case .coreDataError(let error): return "Data error: \(error.localizedDescription)"
           case .cloudKitError(let error): return "Sync error: \(error.localizedDescription)"
           case .validationError(let msg): return msg
           case .notFound(let item): return "\(item) not found"
           case .unauthorized: return "You don't have permission for this action"
           }
       }
   }
   ```

2. **Standardize Service Error Properties** (1-1.5h)
   - Update all services to use consistent pattern:
     ```swift
     @Published var isLoading: Bool = false
     @Published var error: ServiceError?
     ```
   - **Services to update**: HouseholdService, MealPlanService, CloudKitSyncMonitor

3. **Testing** (0.5h)
   - Verify error messages display correctly
   - Test error clearing

**Deliverables:**
- ✅ ServiceError enum created
- ✅ 3+ services standardized
- ✅ Consistent error UX

**Success Metrics:**
- All services use ServiceError
- Error messages user-friendly
- No console-only errors

---

### **PHASE 2: Architectural Improvements** (40-50 hours, 6 weeks)

**Objective**: Improve testability, reduce coupling, establish consistent patterns

**M9.5: Dependency Injection** (12-15 hours)

**Tasks:**
1. **Audit PersistenceController.shared Usage** (2h)
   - Find all 24 references
   - Categorize by context (View, Service, Repository)
   - Create migration plan

2. **Implement Environment-based Injection** (6-8h)
   - Update Views to use `@Environment(\.managedObjectContext)`
   - Create service initializers accepting context
   - Refactor in priority order:
     1. RecipeListView
     2. GroceryListDetailView
     3. AddIngredientsToListView
     4. MealPlanDetailView
     5. ManageCategoriesView

3. **Service Factory Pattern** (2-3h)
   - Create `ServiceFactory` for service initialization
   - Inject dependencies (context, other services)
   - Enable testing with mock services

4. **Testing** (2h)
   - Create mock PersistenceController for tests
   - Write unit tests for services
   - Verify in-memory Core Data works

**Deliverables:**
- ✅ Environment injection in 5+ major views
- ✅ ServiceFactory implemented
- ✅ Mock testing infrastructure
- ✅ 10+ unit tests for services

**Success Metrics:**
- PersistenceController.shared usage: 24 → 5 references
- Services testable in isolation
- Test suite runs in < 10 seconds

---

**M9.6: Service Layer Consistency** (10-12 hours)

**Tasks:**
1. **Standardize Service Interfaces** (4-5h)
   - Define service lifecycle guidelines
   - Document singleton vs. per-view patterns
   - Establish async/await as standard

   **Guidelines:**
   - **Singleton**: Stateless or app-wide state (PersistenceController, HouseholdService)
   - **Per-View**: View-specific state (Search, temporary data)
   - **Async/await**: All async operations (no completion handlers)

2. **Refactor Completion Handlers to Async/Await** (4-5h)
   - **Files to update**:
     - AddIngredientsToListView: `prepareIngredientsAndTemplates(completion:)`
     - RecipeScalingService: Any callback patterns

   ```swift
   // Before
   func prepareIngredientsAndTemplates(completion: @escaping (Result<[PreparedIngredient], Error>) -> Void)

   // After
   func prepareIngredientsAndTemplates() async throws -> [PreparedIngredient]
   ```

3. **Documentation** (2h)
   - Create `docs/architecture/service-layer-guidelines.md`
   - Document patterns and anti-patterns
   - Add examples

**Deliverables:**
- ✅ Service guidelines documented
- ✅ Async/await migration complete
- ✅ Consistent error handling
- ✅ Architecture documentation

**Success Metrics:**
- All services follow guidelines
- No completion handler patterns remain
- Documentation complete

---

**M9.7: View Decomposition - RecipeListView** (8-10 hours)

**Objective**: Reduce RecipeListView from 1,204 lines to ~400 lines (67% reduction)

**Tasks:**
1. **Extract Test Data Generation** (1-2h)
   - Create `forager/Utilities/TestDataGenerator.swift`
   - Move 276 lines (lines 284-560) to new file
   - Make accessible from Settings or DEBUG menu only

2. **Extract RecipeDetailView** (3-4h)
   - Create `forager/Views/Recipes/RecipeDetailView.swift`
   - Move 434 lines (lines 731-1165) to new file
   - Update navigation to new file

3. **Create RecipeRowView Component** (2-3h)
   - Create `forager/Views/Recipes/RecipeRowView.swift`
   - Extract reusable row component
   - Add variants: compact, detailed, search result

4. **Extract RecipeSearchViewModel** (2h)
   - Create `forager/ViewModels/RecipeSearchViewModel.swift`
   - Move search logic out of view
   - Implement filtering, sorting, search

5. **Testing** (1h)
   - Verify all functionality preserved
   - Test navigation flows
   - Check performance unchanged

**Deliverables:**
- ✅ 4 new files created
- ✅ RecipeListView: 1,204 → ~400 lines
- ✅ Improved testability
- ✅ Reusable components

**Success Metrics:**
- RecipeListView < 450 lines
- Zero feature regressions
- Navigation works identically
- Performance maintained

---

**M9.8: View Decomposition - AddIngredientsToListView** (8-10 hours)

**Objective**: Reduce AddIngredientsToListView from 901 lines to ~500 lines (45% reduction)

**Tasks:**
1. **Extract IngredientListService** (3-4h)
   - Create `Services/IngredientListService.swift`
   - Move business logic (lines 262-321)
   - Methods:
     - `prepareIngredients(from:servings:) async throws`
     - `addToList(_:ingredients:) async throws`

2. **Centralize Scaling Logic** (2-3h)
   - Move all scaling to `RecipeScalingService`
   - Remove inline calculations
   - Use service methods exclusively

3. **Extract Category Assignment Coordinator** (2-3h)
   - Create `forager/Coordinators/CategoryAssignmentCoordinator.swift`
   - Handle template creation + category assignment flow
   - Simplify view logic

4. **Testing** (1h)
   - Test ingredient preparation
   - Test scaling accuracy
   - Test category assignment

**Deliverables:**
- ✅ 2 new service/coordinator files
- ✅ AddIngredientsToListView: 901 → ~500 lines
- ✅ Business logic testable
- ✅ Simplified view code

**Success Metrics:**
- View < 550 lines
- Logic testable in isolation
- No feature changes

---

**M9.9: View Decomposition - ManageCategoriesView** (6-8 hours)

**Objective**: Reduce ManageCategoriesView from 751 lines to ~400 lines

**Tasks:**
1. **Extract CategoryManagementViewModel** (3-4h)
   - Create `forager/ViewModels/CategoryManagementViewModel.swift`
   - Move deletion/reassignment logic
   - Methods:
     - `prepareDeletion(category:) async`
     - `executeReassignment(from:to:) async throws`
     - `validateDeletion(category:) -> DeletionStatus`

2. **Extract Subviews** (2-3h)
   - Create `forager/Views/Categories/CategorySelectionView.swift`
   - Create `forager/Views/Categories/CategorySelectionRow.swift`
   - Move embedded views to separate files

3. **Move Logic to CategoryRepository** (1h)
   - Add `reassignItems(from:to:) async throws` to repository
   - Remove direct Core Data manipulation from view

4. **Testing** (1h)
   - Test deletion scenarios
   - Test reassignment
   - Verify edge cases

**Deliverables:**
- ✅ ViewModel + 2 subviews created
- ✅ ManageCategoriesView: 751 → ~400 lines
- ✅ Repository pattern extended
- ✅ Testable deletion logic

**Success Metrics:**
- View < 450 lines
- ViewModel testable
- Zero data loss bugs

---

### **PHASE 3: Performance & Data Model** (60-70 hours, 8 weeks)

**Objective**: Optimize critical paths, fix data model issues

**M9.10: Ingredient Normalization Optimization** (6-8 hours)

**Tasks:**
1. **Implement Normalization Cache** (3-4h)
   - Add `IngredientTemplateService.normalizationCache: [String: String]`
   - Cache normalized results
   - LRU eviction (max 500 entries)

2. **Optimize Normalization Passes** (2-3h)
   - Combine multiple string passes
   - Pre-compile regex patterns (currently recreated each call)
   - Profile improvements

3. **Benchmark** (1h)
   - Measure before/after performance
   - Test with 1,000+ ingredient lookups
   - Document improvement

**Deliverables:**
- ✅ Normalization cache implemented
- ✅ Regex patterns pre-compiled
- ✅ Performance benchmark report

**Success Metrics:**
- Normalization time: 50-70% faster
- Cache hit rate: > 80%
- Memory overhead: < 2MB

---

**M9.11: Core Data Cascade Delete Rules** (4-6 hours)

**Tasks:**
1. **Audit Current Delete Behavior** (1-2h)
   - Document all entity relationships
   - Test deletion scenarios
   - Identify orphan risks

2. **Configure Cascade Rules** (2-3h)
   - Open `forager.xcdatamodeld`
   - Set deletion rules:
     - `MealPlan → PlannedMeal`: Cascade
     - `Recipe → Ingredient`: Cascade
     - `WeeklyList → GroceryListItem`: Cascade
     - `Household → *`: Nullify (preserve recipes)
     - `Category → IngredientTemplate`: Nullify (don't cascade)

3. **Add Deletion Tests** (1h)
   - Test each cascade rule
   - Verify no orphans created
   - Test edge cases

**Deliverables:**
- ✅ Cascade delete rules configured
- ✅ Deletion behavior documented
- ✅ Test suite for deletions

**Success Metrics:**
- Zero orphaned records
- Deletion tests pass
- Documented in architecture docs

---

**M9.12: Category String to Relationship Migration** (10-12 hours)

**Objective**: Replace string-based category storage with Core Data relationships

**Tasks:**
1. **Data Model Changes** (2-3h)
   - Add `categoryEntity` relationship to `IngredientTemplate`
   - Add `categoryEntity` relationship to `GroceryListItem`
   - Keep `category` string as deprecated
   - Update fetch requests

2. **Write Migration** (3-4h)
   - Create `CategoryMigrationService`
   - Map string values to Category entities
   - Handle missing categories (create or default)
   - Verify data integrity

3. **Update All Category Assignment Code** (3-4h)
   - **Files to update**:
     - ManageCategoriesView (reassignment logic)
     - IngredientTemplateService
     - GroceryListDetailView
     - AddListItemView
   - Replace string assignments with relationship assignments

4. **Testing & Validation** (2h)
   - Test migration on test data
   - Verify referential integrity
   - Test category renames propagate
   - Rollback plan documented

**Deliverables:**
- ✅ Data model updated
- ✅ Migration service implemented
- ✅ All code using relationships
- ✅ Migration tested

**Success Metrics:**
- 100% string categories migrated
- Zero data loss
- Category renames propagate automatically
- Rollback tested

---

**M9.13: SwiftUI View Optimization** (8-10 hours)

**Tasks:**
1. **Reduce @StateObject Usage** (3-4h)
   - Audit all views
   - Convert to `@Environment` where appropriate
   - Move shared services to environment
   - Document lifecycle decisions

2. **Decompose Complex View Hierarchies** (3-4h)
   - Break down RecipeDetailView ingredientsSection
   - Create focused subviews:
     - `IngredientsSectionView`
     - `IngredientCategoryView`
     - `IngredientRowView`
   - Apply `@ViewBuilder` where needed

3. **Extract ViewModels** (2-3h)
   - Create ViewModels for views with complex state
   - Move business logic out of views
   - Examples:
     - `CategoryManagementViewModel` (already in M9.9)
     - `RecipeDetailViewModel`
     - `MealPlanViewModel`

**Deliverables:**
- ✅ @StateObject usage reduced by 50%
- ✅ 10+ focused subviews created
- ✅ 3+ ViewModels implemented
- ✅ Improved view performance

**Success Metrics:**
- View re-render count reduced
- Smoother scrolling
- Memory usage improved

---

**M9.14: Batch Fetching Implementation** (6-8 hours)

**Tasks:**
1. **Implement Prefetching** (3-4h)
   - Add `relationshipKeyPathsForPrefetching` to fetch requests
   - Priority areas:
     - Recipe → Ingredients → IngredientTemplate → Category
     - WeeklyList → GroceryListItem → IngredientTemplate
     - MealPlan → PlannedMeal → Recipe

2. **Template Batch Fetching** (2-3h)
   - Create `IngredientTemplateRepository.batchFetch(names:)`
   - Use in AddIngredientsToListView
   - Use in recipe ingredient processing

3. **Performance Testing** (1h)
   - Profile with Instruments
   - Measure fetch count reduction
   - Document improvements

**Deliverables:**
- ✅ Prefetching configured
- ✅ Batch fetch methods added
- ✅ Performance report

**Success Metrics:**
- Core Data faults reduced by 60-80%
- Page load time improved
- Smoother UI interactions

---

### **PHASE 4: Quality & Sustainability** (15-20 hours, 3 weeks)

**Objective**: Prevent future technical debt, establish quality standards

**M9.15: Coding Standards Documentation** (3-4 hours)

**Tasks:**
1. **Create Standards Document** (2-3h)
   - Create `docs/architecture/coding-standards.md`
   - Cover:
     - SwiftUI patterns (when to use @State, @StateObject, @ObservedObject)
     - Service patterns (singleton vs per-view)
     - Error handling (always use ServiceError)
     - Core Data patterns (background context usage)
     - Naming conventions
     - File organization

2. **Add Examples** (1h)
   - Good vs bad examples for each pattern
   - Reference real code in the codebase

**Deliverables:**
- ✅ Comprehensive coding standards doc
- ✅ Examples for all patterns
- ✅ Team-reviewed and approved

---

**M9.16: PR Review Checklist** (2-3 hours)

**Tasks:**
1. **Create Checklist** (1-2h)
   - Create `docs/pull-request-checklist.md`
   - Include:
     - ✅ No code duplication introduced
     - ✅ Services follow established patterns
     - ✅ Views < 500 lines
     - ✅ Error handling uses ServiceError
     - ✅ Core Data used safely (thread-aware)
     - ✅ Tests added for new functionality
     - ✅ Performance regression checked

2. **Integrate with GitHub** (1h)
   - Add as PR template
   - Update contributing guidelines

**Deliverables:**
- ✅ PR checklist created
- ✅ GitHub integration complete

---

**M9.17: Unit Test Framework** (8-10 hours)

**Tasks:**
1. **Setup Testing Infrastructure** (2-3h)
   - Create `foragerTests/` directory structure
   - Configure test target
   - Setup in-memory Core Data for tests

2. **Write Tests for Utilities** (3-4h)
   - Test `Category.emoji(for:)`
   - Test `QuantityFormatter`
   - Test `IngredientParsingService.normalize()`
   - Test `RecipeScalingService.scale()`

3. **Write Tests for Services** (3-4h)
   - Test `HouseholdService` with mocks
   - Test `IngredientTemplateService`
   - Test `CategoryRepository`

**Deliverables:**
- ✅ Test infrastructure complete
- ✅ 30+ unit tests added
- ✅ CI integration ready

**Success Metrics:**
- Test coverage ≥ 60% for new code
- All tests pass in < 15 seconds
- Tests run automatically in CI

---

**M9.18: Logging Framework** (3-4 hours)

**Tasks:**
1. **Implement Logger** (2-3h)
   - Create `forager/Utilities/Logger.swift`

   ```swift
   enum LogLevel { case debug, info, warning, error }

   struct Logger {
       static func log(
           _ message: String,
           level: LogLevel = .info,
           file: String = #file,
           function: String = #function,
           line: Int = #line
       ) {
           #if DEBUG
           let filename = (file as NSString).lastPathComponent
           print("[\(level)] \(filename):\(line) \(function) - \(message)")
           #endif
       }
   }
   ```

2. **Replace Print Statements** (1h)
   - Find all `print()` statements
   - Replace with appropriate log level
   - Remove unnecessary logs

**Deliverables:**
- ✅ Logger implemented
- ✅ Print statements replaced
- ✅ Log levels documented

**Success Metrics:**
- Consistent logging format
- Easy to filter logs
- No console spam in production

---

## 📈 **SUCCESS METRICS**

### **Code Quality Metrics**

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| **Code Duplication** | ~300 lines | 0 lines | Static analysis |
| **Average File Size** | 600 lines | 400 lines | Line count |
| **Largest File** | 1,204 lines | < 500 lines | RecipeListView size |
| **PersistenceController.shared refs** | 24 | < 5 | Code search |
| **Test Coverage** | ~10% | ≥ 60% | Xcode coverage |

### **Performance Metrics**

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| **Template Lookup Time** | 50-100ms | < 10ms | Instruments profiling |
| **100 Ingredients Processing** | ~5s | < 1s | Performance test |
| **Recipe List Load** | 300ms | < 150ms | Time Profiler |
| **Core Data Faults** | ~500/load | < 100/load | Core Data Instrument |
| **Cache Hit Rate** | N/A | > 85% | Analytics |

### **Architecture Metrics**

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| **Testable Services** | 20% | 90% | Unit test coverage |
| **Views with ViewModels** | 0% | 60% | Architecture audit |
| **Async/Await vs Callbacks** | 60/40 | 95/5 | Code search |
| **Error Handling Consistency** | 40% | 100% | ServiceError usage |

---

## ⚠️ **RISKS & MITIGATION**

### **High Risk: Data Migration Failures**

**Risk:** Category string-to-relationship migration could lose data or corrupt database

**Mitigation:**
- Implement full rollback mechanism
- Test on copy of production data
- Phased rollout (test users first)
- Keep string properties as backup for 1-2 releases

**Contingency:** Rollback script reverting to string-based storage

---

### **Medium Risk: Performance Regression**

**Risk:** Refactoring could accidentally introduce performance issues

**Mitigation:**
- Benchmark all major changes
- Use Instruments profiling before/after
- Automated performance tests in CI
- Monitor analytics for slowdowns

**Contingency:** Revert specific optimization if regression detected

---

### **Medium Risk: Scope Creep**

**Risk:** "While we're at it" syndrome leads to feature additions

**Mitigation:**
- Strict adherence to refactoring-only scope
- PR reviews enforce no feature changes
- Separate backlog for "nice to have" improvements

**Contingency:** Defer non-critical items to M10+

---

### **Low Risk: Breaking Changes**

**Risk:** Refactoring breaks existing functionality

**Mitigation:**
- Comprehensive testing after each phase
- Incremental changes with small PRs
- Feature flags for risky changes
- Manual QA of critical flows

**Contingency:** Automated rollback via git revert

---

## 📋 **REQUIREMENTS SUMMARY**

### **Functional Requirements**

| ID | Requirement | Phase | Priority |
|----|-------------|-------|----------|
| **FR-TD-000** | Achieve zero-warning build baseline | Phase 0 | P0 |
| **FR-TD-001** | Consolidate duplicated utility functions | Phase 1 | P0 |
| **FR-TD-002** | Add Core Data indexes for performance | Phase 1 | P0 |
| **FR-TD-003** | Fix thread safety violations | Phase 1 | P0 |
| **FR-TD-004** | Standardize error handling patterns | Phase 1 | P0 |
| **FR-TD-005** | Implement dependency injection | Phase 2 | P0 |
| **FR-TD-006** | Standardize service interfaces (async/await) | Phase 2 | P0 |
| **FR-TD-007** | Decompose RecipeListView (1204 → 400 lines) | Phase 2 | P1 |
| **FR-TD-008** | Decompose AddIngredientsToListView (901 → 500 lines) | Phase 2 | P1 |
| **FR-TD-009** | Decompose ManageCategoriesView (751 → 400 lines) | Phase 2 | P1 |
| **FR-TD-010** | Optimize ingredient normalization | Phase 3 | P1 |
| **FR-TD-011** | Configure Core Data cascade delete rules | Phase 3 | P1 |
| **FR-TD-012** | Migrate category strings to relationships | Phase 3 | P0 |
| **FR-TD-013** | Implement batch fetching with prefetching | Phase 3 | P0 |
| **FR-TD-014** | Optimize SwiftUI view hierarchies | Phase 3 | P2 |
| **FR-TD-015** | Create coding standards documentation | Phase 4 | P1 |
| **FR-TD-016** | Implement PR review checklist | Phase 4 | P1 |
| **FR-TD-017** | Add unit test framework | Phase 4 | P0 |
| **FR-TD-018** | Implement logging framework | Phase 4 | P2 |

### **Non-Functional Requirements**

| ID | Requirement | Target | Priority |
|----|-------------|--------|----------|
| **NFR-TD-001** | Zero feature regressions | 0 bugs | P0 |
| **NFR-TD-002** | Test coverage for new utilities | ≥ 80% | P0 |
| **NFR-TD-003** | Template lookup performance | < 10ms | P0 |
| **NFR-TD-004** | Code duplication reduction | 100% eliminated | P0 |
| **NFR-TD-005** | Largest file size | < 500 lines | P1 |
| **NFR-TD-006** | Core Data fault reduction | 60-80% fewer | P0 |
| **NFR-TD-007** | Thread Sanitizer clean | 0 warnings | P0 |
| **NFR-TD-008** | Test suite execution time | < 15 seconds | P1 |
| **NFR-TD-009** | Documentation completeness | 100% | P1 |
| **NFR-TD-010** | Migration data loss | 0 records | P0 |

---

## 🎯 **DEPENDENCIES**

### **Prerequisites**
- ✅ M7 Complete: CloudKit sync stable, no active development
- ✅ M8 Complete: Analytics provide usage data for optimization priorities
- ✅ Clean git state: All features merged, no pending PRs

### **Blocking Dependencies**
- **None**: M9 is independent refactoring work

### **Related Work**
- **M10+**: Future features will benefit from cleaner architecture
- **Testing**: Establishes foundation for ongoing test development

---

## 📅 **TIMELINE ESTIMATE**

### **Aggressive Timeline** (137 hours)
- **Phase 0**: 1 session (2h) - Warning resolution
- **Phase 1**: 3 weeks (20h) - Quick wins
- **Phase 2**: 6 weeks (40h) - Architecture
- **Phase 3**: 8 weeks (60h) - Performance
- **Phase 4**: 3 weeks (15h) - Quality
- **Total**: 20 weeks (~5 months part-time)

### **Conservative Timeline** (176 hours)
- **Phase 0**: 1 session (3h) - Warning resolution
- **Phase 1**: 4 weeks (25h) - Quick wins
- **Phase 2**: 8 weeks (50h) - Architecture
- **Phase 3**: 10 weeks (70h) - Performance
- **Phase 4**: 4 weeks (20h) - Quality
- **Total**: 26 weeks (~6.5 months part-time)

### **Recommended Approach**
- **Phased rollout**: Complete Phase 1, validate, then Phase 2, etc.
- **Buffer**: Add 20% time for unexpected issues
- **Realistic**: 6-7 months at 8-10 hours/week

---

## 🚀 **NEXT STEPS**

### **Immediate Actions**
1. ✅ Review and approve PRD
2. ⏳ Complete M7 and M8 work
3. ⏳ Renumber existing M9+ milestones
4. ⏳ Update roadmap with M9 phases
5. ⏳ Create tracking issues for each phase

### **Phase 1 Kickoff** (After M7/M8)
1. Create feature branch: `feature/M9.1-utility-consolidation`
2. Setup benchmarking infrastructure
3. Begin M9.1: Utility Consolidation
4. Daily progress tracking in learning notes

---

## 📚 **REFERENCES**

### **Related Documents**
- [M7.2.3 PRD](./m7.2.3-cloudkit-hardening-household-repositories.md) - Similar refactoring effort
- [Requirements Doc](../requirements.md) - Overall project requirements
- [Roadmap](../roadmap.md) - Project timeline

### **Technical Debt Analysis**
- Generated: January 4, 2026
- Files Analyzed: 45 Swift files
- Issues Found: 29 (10 High, 14 Medium, 5 Low)
- Agent ID: a1fc706

### **Architecture Decisions**
- ADR 008: Shared Zone Architecture (M7.2)
- Future: ADR for Dependency Injection pattern
- Future: ADR for Service layer standards

---

**Document Status**: DRAFT
**Next Review**: After M8 completion
**Owner**: Rich Hayn
**Last Updated**: February 6, 2026
