# Spec: Grocery Lists

## Overview

Weekly grocery list management with item CRUD, category-based organization matching store layout, staples automation, completion tracking, consolidation of duplicate items across recipes, and recipe source attribution. The grocery list is the primary shopping interface and the convergence point for meal planning and recipe integration.

## Requirements

- REQ-001: The system MUST allow users to create named weekly grocery lists (WeeklyList entity) with automatic date tracking.
  - Scenario: Given the user is on the Lists tab, When they tap "New List", Then a new WeeklyList is created with the current date and appears in the list view.

- REQ-002: The system MUST support full CRUD operations on grocery list items (GroceryListItem entity) with name, quantity, and category.
  - Scenario: Given an open grocery list, When the user adds an item "2 cups flour" to the Baking category, Then a GroceryListItem is created with structured quantity data and the correct category assignment.

- REQ-003: The system MUST allow marking items as complete/incomplete with visual feedback (strikethrough, color shift, haptic).
  - Scenario: Given an unchecked grocery item, When the user taps the checkbox, Then the item shows strikethrough styling, the completion percentage updates, and haptic feedback fires.

- REQ-004: The system MUST display a progress bar showing completion percentage for each grocery list.
  - Scenario: Given a list with 10 items where 3 are checked, When the user views the list, Then the progress bar shows 30% with animated updates.

- REQ-005: The system MUST auto-complete a list when all items are marked done.
  - Scenario: Given a list with 9 of 10 items checked, When the user checks the last item, Then the list status changes to complete automatically.

- REQ-006: The system MUST support custom categories with user-defined names, colors (12-color palette), and drag-and-drop reordering for store-layout optimization.
  - Scenario: Given the Manage Categories view, When the user drags "Produce" above "Dairy", Then the sort order persists and grocery items display in the new category order.

- REQ-007: The system MUST protect categories that contain items from accidental deletion by showing a warning with a reassignment option.
  - Scenario: Given a category "Snacks" with 5 assigned items, When the user tries to delete it, Then a confirmation dialog appears offering to reassign items to another category.

- REQ-008: The system MUST support marking items as staples and auto-populating staples into new grocery lists with category preservation.
  - Scenario: Given "Milk" is marked as a staple in the Dairy category, When the user creates a new weekly list, Then "Milk" appears pre-populated in the Dairy section.

- REQ-009: The system MUST consolidate duplicate items from multiple recipes by merging compatible quantities (e.g., "1 cup flour" + "2 cups flour" = "3 cups flour") with a preview step requiring user approval.
  - Scenario: Given a list with "1 cup flour" from Tacos and "2 cups flour" from Bread, When the user triggers consolidation, Then a preview shows "3 cups flour [Tacos, Bread]" and waits for confirmation before merging.

- REQ-010: The system MUST display recipe source tags on grocery items showing which recipes contributed each ingredient.
  - Scenario: Given "Ground beef" was added from both "Tacos" and "Spaghetti" recipes, When the user views the item, Then small recipe badges "[Tacos] [Spaghetti]" appear below the item name.

- REQ-011: The system MUST support unit conversion during consolidation (cups to tablespoons, pounds to ounces) with 100% conversion accuracy.
  - Scenario: Given "1 cup butter" and "2 tbsp butter" on the same list, When consolidation runs, Then the system merges them as "1 cup + 2 tbsp butter" or converts to a single unit.

- REQ-012: All grocery list operations MUST route through the service layer (GroceryListItemService, WeeklyListService) and MUST NOT call context.save() from views.
  - Scenario: Given a view that needs to add a grocery item, When the view calls the service method, Then the service handles Core Data persistence and the view only observes changes via @FetchRequest.

- REQ-013: All fetches on grocery list entities MUST include a householdKey predicate for scope-aware data isolation (ADR 013).
  - Scenario: Given a user in household "Smith Family", When the app fetches grocery lists, Then only lists with householdKey matching "Smith Family" are returned, excluding any personal-scope or other-household data.

## Implementation Notes

- Core entities: WeeklyList, GroceryListItem, Category, IngredientTemplate
- GroceryListItem uses snapshot pattern: category is captured at creation time from the template's category, not dynamically resolved
- Consolidation logic lives in QuantityMergeService with ConsolidationPreviewView for user approval
- Items grouped by category in the default view; "Group by Store" is an alternate grouping (see store-aware-shopping spec)
- HouseholdScoped entities (WeeklyList, GroceryListItem, Category) MUST use ManagedObjectFactory.make() per ADR 014
