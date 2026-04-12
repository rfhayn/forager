## Why

Top-level HouseholdScoped entities (WeeklyList, Recipe, MealPlan, PlannedMeal, Category, IngredientTemplate) are created via `Entity(context:)` instead of `ManagedObjectFactory.make()` in ~15 production code paths. These entities land in the private store with no household assignment, becoming invisible to household members and never syncing via CloudKit. This is a pre-launch data corruption risk that affects every household user.

The root cause is that `factory` is declared as `ManagedObjectFactory?` across all services and repositories, forcing every creation site to have an `if let factory` / `else` fallback branch. The fallback branches silently create unscoped entities.

## What Changes

- **Make `factory` non-optional** in all services and repositories that create HouseholdScoped entities (11 files). Remove all `if let factory` / `else` fallback branches.
- **Fix CreateRecipeView ghost recipe fallback** — catch block creates `Recipe(context:)` with no household. Replace with error propagation to user.
- **Fix HouseholdService force unwrap** — `throw lastError!` at line 2456 crashes if nil. Replace with typed error.
- **Wire factory into Household*Repository classes** — `HouseholdCategoryRepository`, `HouseholdPlannedMealRepository`, `HouseholdIngredientTemplateRepository` accept factory in init but are always instantiated without it. Pass factory from parent service.
- **Fix ManageCategoriesView** — inline `Category(context:)` for "Uncategorized" bypasses factory. Route through `CategoryRepository.getOrCreate()`.
- **Route view-level `try? context.save()`** through service layer (4 production locations).
- **Replace 5 force unwraps** with guard-let in production code.
- **Add critical test coverage** for ManagedObjectFactory, HouseholdScopeProvider, and CategoryDeduplicator.

## Capabilities

### New Capabilities

_None — this is a correctness and safety fix, not new functionality._

### Modified Capabilities

- `household-sharing`: Factory enforcement becomes mandatory (non-optional) for all HouseholdScoped entity creation. Fallback creation paths removed.

## Impact

- **Services (11 files)**: WeeklyListService, MealPlanService, RecipeService, IngredientTemplateService, GroceryListItemService, CategoryRepository, PlannedMealRepository, IngredientTemplateRepository, HouseholdCategoryRepository, HouseholdPlannedMealRepository, HouseholdIngredientTemplateRepository
- **Views (4 files)**: CreateRecipeView, ManageCategoriesView, GroceryListDetailView, WeeklyListsView, MealPlanListView, MealPlanDetailView
- **App bootstrap (1 file)**: foragerApp.swift — factory injection point
- **Tests (3 new files)**: ManagedObjectFactoryTests, HouseholdScopeProviderTests, CategoryDeduplicatorTests
- **No Core Data schema changes** — this is purely code-level enforcement
- **No API changes** — internal service signatures only
