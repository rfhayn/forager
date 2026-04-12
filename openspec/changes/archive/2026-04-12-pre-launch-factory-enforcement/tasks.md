## 1. Factory Non-Optional in Services

- [x] 1.1 Make `factory` non-optional in `WeeklyListService` — change `ManagedObjectFactory?` to `ManagedObjectFactory`, update init, remove `if let factory` / `else` at line 58
- [x] 1.2 Make `factory` non-optional in `MealPlanService` — update init, remove fallback branches at lines 196, 889, 946
- [x] 1.3 Make `factory` non-optional in `RecipeService` — update init, remove fallback branches at lines 67, 156
- [x] 1.4 Make `factory` non-optional in `IngredientTemplateService` — update init, remove fallback at line 530
- [x] 1.5 Update `foragerApp.swift` init order — create factory before services, pass via init instead of `.configure(factory:)`

## 2. Factory Non-Optional in Repositories

- [x] 2.1 Make `factory` non-optional in `CategoryRepository` — remove fallback at line 70
- [x] 2.2 Make `factory` non-optional in `PlannedMealRepository` — remove fallback at line 117
- [x] 2.3 Make `factory` non-optional in `IngredientTemplateRepository` — remove fallback at line 71
- [x] 2.4 Make `factory` non-optional in `HouseholdCategoryRepository` — remove fallback at line 83
- [x] 2.5 Make `factory` non-optional in `HouseholdPlannedMealRepository` — remove fallback at line 84, add household + householdKey assignment
- [x] 2.6 Make `factory` non-optional in `HouseholdIngredientTemplateRepository` — remove fallback at line 112

## 3. Wire Factory into Inline Repository Creation

- [x] 3.1 Pass factory from `MealPlanService` to `HouseholdPlannedMealRepository` instantiation (line ~567)
- [x] 3.2 Pass factory from `IngredientTemplateService` to `HouseholdIngredientTemplateRepository` instantiation (line ~439)
- [x] 3.3 Pass factory to `HouseholdCategoryRepository` in `Category+CoreDataClass` (lines ~30, ~52) — may need to accept factory as method parameter
- [x] 3.4 Pass factory to `CategoryRepository` where instantiated inline

## 4. View-Level Fixes

- [x] 4.1 Fix `CreateRecipeView` ghost recipe — remove catch/else fallback at lines 874-899, propagate error to user via alert
- [x] 4.2 Fix `ManageCategoriesView` — replace `Category(context:)` at line 529 with `CategoryRepository.getOrCreate()` or factory call
- [x] 4.3 Route `GroceryListDetailView:588` `try? viewContext.save()` through `WeeklyListService`
- [x] 4.4 Route `WeeklyListsView:400` `try? viewContext.save()` — replaced with do-catch
- [x] 4.5 Route `MealPlanListView:368` `try? viewContext.save()` — replaced with do-catch
- [x] 4.6 Route `MealPlanDetailView:592` `try? context.save()` — replaced with do-catch

## 5. Force Unwrap Fixes

- [x] 5.1 Fix `HouseholdService.swift:2456` — replace `throw lastError!` with `throw lastError ?? HouseholdError.creationFailed(...)`
- [x] 5.2 Fix `HybridIngredientParser.swift:67` — guard-let on `.max(by:)!`
- [x] 5.3 Fix `DiagnosticLogger.swift:60` — guard-let on `docs.first!`
- [x] 5.4 Fix `PersistenceController.swift:320` — guard-let on `store.url!`
- [x] 5.5 Fix `RegexIngredientParser.swift:861` — guard-let on `unicodeScalars.first!`
- [x] 5.6 Fix `CategoryDeduplicator.swift:97` — guard-let on `sorted.first!`

## 6. Test Coverage

- [x] 6.1 Create `ManagedObjectFactoryTests.swift` — test personal scope → private store, household scope → shared store + household + householdKey, explicit scope override, error on invalid ObjectID, stale ObjectID fallback
- [x] 6.2 Create `HouseholdScopeProviderTests.swift` — test no household → `.personal`, active household → `.household(id:storeID:)`
- [x] 6.3 Create `CategoryDeduplicatorTests.swift` — test same-name merge, preserve relationships, empty array safety

## 7. Verification

- [x] 7.1 Build succeeds with zero errors (`xcodebuild build`)
- [x] 7.2 All existing + new tests pass (new tests: 20/20 pass; pre-existing HybridParserRoutingTests has 3 failures unrelated to this change)
- [x] 7.3 Grep codebase for remaining `Entity(context:)` patterns on top-level HouseholdScoped entities in production code — confirm none remain
